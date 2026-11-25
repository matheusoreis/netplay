class_name FramedTransport
extends RefCounted


class FramedTransportClient extends Network.TransportClient:
	const PREFIX_LEN: int = 2
	const MAX_PACKET_SIZE: int = 1024 * 4
	const MAX_PACKET_BACKLOG: int = 32
	const MAX_PACKET_PER_TICK: int = 8


	var _max_packet_size: int
	var _max_packet_backlog: int
	var _max_packet_per_tick: int
	var _framed: Framed
	var _client: FramedClient


	func _init(
		max_packet_size: int = MAX_PACKET_SIZE,
		max_packet_backlog: int = MAX_PACKET_BACKLOG,
		max_packet_per_tick: int = MAX_PACKET_PER_TICK,
	) -> void:
		_max_packet_size = max_packet_size
		_max_packet_backlog = max_packet_backlog
		_max_packet_per_tick = max_packet_per_tick
		_framed = Framed.new()


	func connect_to_server(host: String, port: int) -> void:
		var opts: FramedClientOptions = FramedClientOptions.new()
		opts.prefix_len = PREFIX_LEN
		opts.endian = Framed.LITTLE
		opts.endpoint = '%s:%d' % [host, port]
		opts.max_packet_size = _max_packet_size
		opts.max_packet_backlog = _max_packet_backlog
		opts.max_packet_per_tick = _max_packet_per_tick

		var client: FramedClient = _framed.client(opts)
		if client == null:
			error.emit()
			return

		_client = client
		_client.connected.connect(_on_connected)
		_client.disconnected.connect(_on_disconnected)
		_client.packet_received.connect(_on_packet_received)


	func close() -> void:
		_client.disconnect_client()
		await disconnected
		_client = null
		closed.emit()


	func send(buf: PackedByteArray) -> void:
		_client.send(buf)


	func poll(_dt: float) -> void:
		if _framed == null: return
		_framed.poll()
		if _client != null:
			_client.poll()


	func _on_connected(ok: bool) -> void:
		if !ok:
			error.emit()
			return
		connected.emit()


	func _on_disconnected() -> void:
		disconnected.emit()


	func _on_packet_received(packet_buf: PackedByteArray) -> void:
		packet_received.emit(packet_buf)


class FramedTransportServer extends Network.TransportServer:
	const PREFIX_LEN: int = 2
	const MAX_PACKET_SIZE: int = 1024 * 4
	const MAX_PACKET_BACKLOG: int = 32
	const MAX_PACKET_PER_TICK: int = 8


	var _max_packet_size: int
	var _max_packet_backlog: int
	var _max_packet_per_tick: int
	var _framed: Framed
	var _server: FramedServer
	var _peer_ids: Dictionary[int, bool]


	func _init(
		max_packet_size: int = MAX_PACKET_SIZE,
		max_packet_backlog: int = MAX_PACKET_BACKLOG,
		max_packet_per_tick: int = MAX_PACKET_PER_TICK,
	) -> void:
		_max_packet_size = max_packet_size
		_max_packet_backlog = max_packet_backlog
		_max_packet_per_tick = max_packet_per_tick
		_framed = Framed.new()
		_peer_ids = {}


	func open(host: String, port: int, max_clients: int) -> Error:
		var opts: FramedServerOptions = FramedServerOptions.new()
		opts.prefix_len = PREFIX_LEN
		opts.endian = Framed.LITTLE
		opts.endpoint = '%s:%d' % [host, port]
		opts.max_clients = max_clients
		opts.max_packet_size = _max_packet_size
		opts.max_packet_backlog = _max_packet_backlog
		opts.max_packet_per_tick = _max_packet_per_tick

		var server: FramedServer = _framed.server(opts)
		if server == null:
			return ERR_CANT_CREATE

		_server = server
		_server.client_connected.connect(_on_client_connected)
		_server.client_disconnected.connect(_on_client_disconnected)
		_server.packet_received.connect(_on_packet_received)

		return OK


	func poll(_dt: float) -> void:
		if _framed == null: return
		_framed.poll()
		if _server != null:
			_server.poll()


	func send_to(target: Variant, buf: PackedByteArray) -> void:
		if _server == null:
			return

		match typeof(target):
			TYPE_INT:
				var id: int = target as int
				if _peer_ids.has(id):
					_server.send_to(id, buf)
			TYPE_CALLABLE:
				var predicate: Callable = target as Callable
				for id: int in _peer_ids.keys():
					if predicate.call(id):
						_server.send_to(id, buf)
			TYPE_ARRAY:
				var ids: Array = target as Array
				for id: int in ids:
					if _peer_ids.has(id):
						_server.send_to(id, buf)


	func kick(id: int) -> void:
		if !_peer_ids.has(id): return

		_peer_ids.erase(id)
		_server.kick(id)
		client_disconnected.emit(id)


	func close() -> void:
		if _server == null:
			return

		if !_server.is_closed():
			_server.close()
			await _server.closed

		_server = null
		_peer_ids.clear()

		closed.emit()


	func _on_client_connected(peer_id: int) -> void:
		_peer_ids[peer_id] = true
		client_connected.emit(peer_id)


	func _on_client_disconnected(peer_id: int) -> void:
		if !_peer_ids.has(peer_id): return

		_peer_ids.erase(peer_id)
		client_disconnected.emit(peer_id)


	func _on_packet_received(peer_id: int, packet_buf: PackedByteArray) -> void:
		if !_peer_ids.has(peer_id): return

		packet_received.emit(peer_id, packet_buf)
