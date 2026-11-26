class_name Network
extends RefCounted


const VERBOSE: bool = true
const MAX_TASKS: int = 1024
const SCOPE: StringName = "Network"

const EXEC_PACKET_TY: Array[Variant.Type] = [TYPE_INT, TYPE_INT, TYPE_ARRAY]
const INVOKE_PACKET_TY: Array[Variant.Type] = [TYPE_INT, TYPE_INT, TYPE_ARRAY, TYPE_INT]


var _lookup: Dictionary[int, Array]
var _tasks: Array


func _init() -> void:
	_lookup = {}
	_tasks = []
	_tasks.resize(MAX_TASKS)


func register(remote_funcs: Array[Callable]) -> void:
	for fn: Callable in remote_funcs:
		var fn_name: StringName = fn.get_method()
		if fn_name == '<anonymous lambda>':
			if VERBOSE: push_error("[NETWORK] anonymous functions can't be registered")
			continue

		var id: int = ('%s.%s' % [SCOPE, fn_name]).hash()
		if _lookup.has(id):
			var existing: Callable = _lookup[id][0] as Callable
			var args: Array = [SCOPE, fn_name, SCOPE, existing.get_method()]
			if VERBOSE: push_error("[NETWORK] RPC ID conflict: Function [%s.%s] shares the same ID as [%s.%s]." % args)
			continue

		if VERBOSE: print('[NETWORK] %s.%s registered with id %d' % [SCOPE, fn_name, id])
		_lookup[id] = [fn, _get_args_ty(fn.get_object(), fn_name)]


func unregister(remote_funcs: Array[Callable]) -> void:
	for fn: Callable in remote_funcs:
		var id: int = ('%s.%s' % [SCOPE, fn.get_method()]).hash()
		_lookup.erase(id)


@warning_ignore('unused_parameter')
func poll(timeout_ms: int = 0) -> void:
	pass


func _get_args_ty(obj: Object, fn_name: StringName) -> Array[Variant.Type]:
	var args: Array[Variant.Type] = []
	for method: Dictionary in obj.get_method_list():
		if method.name == fn_name:
			for arg: Dictionary in method.args:
				args.push_back(arg.type as Variant.Type)
	return args


class Task extends RefCounted:
	@warning_ignore('unused_signal')
	signal done(value: Variant)


class Client extends Network:
	signal connected()
	signal disconnected()
	@warning_ignore("unused_signal")
	signal error()


	var _host: String
	var _port: int
	var _transport: Transport.TransportClient


	func _init(host: String, port: int, transport: Transport.TransportClient) -> void:
		super()

		_host = host
		_port = port
		_transport = transport
		_transport.connected.connect(connected.emit)
		_transport.disconnected.connect(disconnected.emit)
		_transport.error.connect(error.emit)
		_transport.packet_received.connect(_handle_packet)


	func start() -> void:
		_transport.connect_to_server(_host, _port)


	func stop() -> void:
		_transport.close()
		await _transport.closed


	func poll(timeout_ms: int = 0) -> void:
		var st: int = Time.get_ticks_msec()
		_transport.poll(0.0)
		while Time.get_ticks_msec() - st < timeout_ms:
			_transport.poll(0.0)


	func exec(fn_path: StringName, args: Array = []) -> void:
		var id: int = ('%s.%s' % [SCOPE, fn_path]).hash()
		_send([Enums.PacketKind.EXEC, id, args])


	func invoke(fn_path: StringName, args: Array = []) -> Variant:
		var task_id: int = _tasks.find(null)
		assert(task_id != -1)

		var task: Task = Task.new()
		_tasks[task_id] = task

		var id: int = ('%s.%s' % [SCOPE, fn_path]).hash()
		_send([Enums.PacketKind.INVOKE, id, args, task_id])

		var result: Variant = await task.done
		_tasks[task_id] = null
		return result


	func _send(packet: Array) -> void:
		_transport.send(var_to_bytes(packet))


	func _handle_packet(packet_buf: PackedByteArray) -> void:
		var packet: Array = bytes_to_var(packet_buf) as Array
		assert(packet != null)

		match packet[0] as int:
			Enums.PacketKind.EXEC:
				var fn_id: int = packet[1] as int
				var args: Array = packet[2] as Array
				(_lookup[fn_id][0] as Callable).callv(args)
			Enums.PacketKind.INVOKE:
				var fn_id: int = packet[1] as int
				var args: Array = packet[2] as Array
				var task_id: int = packet[3] as int
				var result: Variant = await (_lookup[fn_id][0] as Callable).callv(args)
				_send([Enums.PacketKind.RESULT, result, task_id])
			Enums.PacketKind.RESULT:
				var value: Variant = packet[1]
				var task_id: int = packet[2] as int
				(_tasks[task_id] as Task).done.emit(value)


class Server extends Network:
	signal client_connected(id: int)
	signal client_disconnected(id: int)

	@warning_ignore("unused_signal")
	signal error()


	var _host: String
	var _port: int
	var _max_clients: int
	var _transport: Transport.TransportServer
	var _sender_id: int


	func _init(host: String, port: int, max_clients: int, transport: Transport.TransportServer) -> void:
		super()

		_host = host
		_port = port
		_max_clients = max_clients
		_transport = transport
		_transport.client_connected.connect(client_connected.emit)
		_transport.client_disconnected.connect(client_disconnected.emit)
		_transport.error.connect(error.emit)
		_transport.packet_received.connect(_handle_packet)


	func start() -> Error:
		return _transport.open(_host, _port, _max_clients)


	func stop() -> void:
		_transport.close()
		await _transport.closed


	func poll(timeout_ms: int = 0) -> void:
		var st: int = Time.get_ticks_msec()
		_transport.poll(0.0)
		while Time.get_ticks_msec() - st < timeout_ms:
			_transport.poll(0.0)


	func exec(target: Variant, fn_path: StringName, args: Array = []) -> void:
		var id: int = ('%s.%s' % [SCOPE, fn_path]).hash()
		_send(target, [Enums.PacketKind.EXEC, id, args])


	func invoke(target: Variant, fn_path: StringName, args: Array = []) -> Variant:
		var task_id: int = _tasks.find(null)
		assert(task_id != -1)

		var task: Task = Task.new()
		_tasks[task_id] = task

		var id: int = ('%s.%s' % [SCOPE, fn_path]).hash()
		_send(target, [Enums.PacketKind.INVOKE, id, args, task_id])

		var result: Variant = await task.done
		_tasks[task_id] = null
		return result


	func sender_id() -> int:
		return _sender_id


	func kick(client_id: int, reason: String = '') -> void:
		_transport.kick(client_id)
		if reason != '' && VERBOSE:
			push_warning('[NETWORK] client %d kicked: %s' % [client_id, reason])


	func _send(target: Variant, packet: Array) -> void:
		_transport.send_to(target, var_to_bytes(packet))


	func _validate_args(args_ty: Array[Variant.Type], args: Array) -> bool:
		if args.size() != args_ty.size():
			return false

		for i: int in args.size():
			if typeof(args[i]) != args_ty[i]:
				return false

		return true


	func _handle_packet(client_id: int, packet_buf: PackedByteArray) -> void:
		_sender_id = client_id

		var packet_value: Variant = bytes_to_var(packet_buf)
		if packet_value == null:
			kick(client_id, 'invalid packet')
			return

		var packet: Array = packet_value as Array
		if packet.size() < 3:
			kick(client_id, 'invalid packet')
			return

		match packet[0] as int:
			Enums.PacketKind.EXEC:
				if !_validate_args(EXEC_PACKET_TY, packet):
					kick(client_id, 'invalid packet')
					return

				var fn_id: int = packet[1] as int
				var value: Variant = _lookup.get(fn_id)
				if value == null:
					kick(client_id, 'attempt to exec invalid function %d' % fn_id)
					return

				var args: Array = packet[2] as Array
				var args_ty: Array[Variant.Type] = value[1] as Array[Variant.Type]
				if _validate_args(args_ty, args):
					(value[0] as Callable).callv(args)
					return

				kick(client_id, 'invalid args')
			Enums.PacketKind.INVOKE:
				if !_validate_args(INVOKE_PACKET_TY, packet):
					kick(client_id, 'invalid packet')
					return

				var fn_id: int = packet[1] as int
				var value: Variant = _lookup.get(fn_id)
				if value == null:
					kick(client_id, 'attempt to invoke invalid function %d' % fn_id)
					return

				var args: Array = packet[2] as Array
				var args_ty: Array[Variant.Type] = value[1] as Array[Variant.Type]
				var task_id: int = packet[3] as int
				if _validate_args(args_ty, args):
					var result: Variant = await (value[0] as Callable).callv(args)
					_send(client_id, [Enums.PacketKind.RESULT, result, task_id])
					return

				kick(client_id, 'invalid args')
			Enums.PacketKind.RESULT:
				if typeof(packet[0]) != TYPE_INT || typeof(packet[2]) != TYPE_INT:
					kick(client_id, 'invalid packet')
					return

				var task_id: int = packet[2] as int
				if task_id < 0 || task_id >= MAX_TASKS:
					kick(client_id, 'invalid task')
					return

				if _tasks[task_id] == null:
					kick(client_id, 'invalid task')
					return

				var value: Variant = packet[1]
				(_tasks[task_id] as Task).done.emit(value)
			_:
				kick(client_id, 'invalid action %d' % (packet[0] as int))
