extends Node2D


@export var transport_kind: Enums.TransportKind = Enums.TransportKind.FRAMED


var _network: Network.Server
var _database: Database

var _loop: Loop


func _ready() -> void:
	if not _start_database():
		return

	await _start_network(_kind_from_args(transport_kind))


func _physics_process(_delta: float) -> void:
	if _database != null:
		_database.poll()

	if _network != null:
		_network.poll()


func _start_database() -> bool:
	var database: Database = Database.new()

	print("[DATABASE] Iniciando banco de dados em %s%s.db..." % [Constants.DATABASE_PATH, Constants.DATABASE_FILENAME])

	var err: Error = database.create(Constants.DATABASE_PATH, Constants.DATABASE_FILENAME)
	if err != OK:
		push_error("[DATABASE] Erro ao iniciar o banco de dados (%s)." % error_string(err))
		return false

	_database = database

	print("[DATABASE] Banco de dados iniciado com sucesso!")
	return true


func _start_network(kind: Enums.TransportKind) -> bool:
	var transport: Transport.TransportServer = _create_transport(kind)
	if transport == null:
		return false

	var parts: PackedStringArray = Constants.ENDPOINT.split(":")
	if parts.size() != 2:
		push_error("[SERVER] Endpoint inválido: %s" % Constants.ENDPOINT)
		return false

	var network: Network.Server = Network.Server.new(
		parts[0],
		parts[1].to_int(),
		Constants.MAX_PEERS,
		transport
	)

	network.client_connected.connect(_on_client_connected)
	network.client_disconnected.connect(_on_client_disconnected)

	await _setup_managers()
	await _setup_events()

	print("[SERVER] Iniciando servidor (%s) em %s..." % [
		str(Enums.TransportKind.find_key(kind)), Constants.ENDPOINT
	])

	var err: Error = network.start()
	if err != OK:
		push_error("[SERVER] Erro ao iniciar o servidor (%s)." % error_string(err))
		return false

	_network = network

	print("[SERVER] Servidor iniciado com sucesso!")
	return true


func _setup_managers() -> void:
	await get_tree().process_frame


func _setup_events() -> void:
	await get_tree().process_frame


func _create_transport(kind: Enums.TransportKind) -> Transport.TransportServer:
	match kind:
		Enums.TransportKind.FRAMED:
			return FramedTransport.FramedTransportServer.new()
		Enums.TransportKind.ENET:
			return EnetTransport.EnetTransportServer.new()
	return null


func _kind_from_args(fallback: Enums.TransportKind) -> Enums.TransportKind:
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--transport="):
			continue

		var key: String = arg.trim_prefix("--transport=").to_upper()
		if Enums.TransportKind.has(key):
			return Enums.TransportKind[key] as Enums.TransportKind

	return fallback


func _on_client_connected(peer_id: int) -> void:
	print("Cliente %d conectado." % peer_id)


func _on_client_disconnected(peer_id: int) -> void:
	print("Cliente %d desconectado." % peer_id)
