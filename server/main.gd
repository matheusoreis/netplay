extends Node2D


@export var transport_kind: Enums.TransportKind = Enums.TransportKind.FRAMED


var _network: Network.Server
var _database: Database

@warning_ignore("unused_private_class_variable")
var _loop: Loop

var _account_repository: AccountRepository
var _map_repository: MapRepository
var _map_collision_repository: MapCollisionRepository
var _map_warp_repository: MapWarpRepository
var _character_repository: CharacterRepository

var _account_manager: AccountManager
var _map_manager: MapManager
var _map_collision_manager: MapCollisionManager
var _map_warp_manager: MapWarpManager
var _character_manager: CharacterManager

var _account_handler: AccountHandler
var _character_handler: CharacterHandler


func _ready() -> void:
	get_tree().auto_accept_quit = false

	if not await _start_database():
		return

	await _load_maps()

	if not _start_network(
		_kind_from_args(transport_kind)
	):
		return


func _physics_process(_delta: float) -> void:
	if _database != null:
		_database.poll()

	if _network != null:
		_network.poll()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await _shutdown()
		get_tree().quit()


func _start_database() -> bool:
	var database: Database = Database.new()

	print("[DATABASE] Iniciando banco de dados em %s%s.db..." % [Constants.DATABASE_PATH, Constants.DATABASE_FILENAME])

	var err: Error = database.create(Constants.DATABASE_PATH, Constants.DATABASE_FILENAME)
	if err != OK:
		push_error("[DATABASE] Erro ao iniciar o banco de dados (%s)." % error_string(err))
		return false

	_database = database

	await _setup_repositories()
	_setup_managers()

	print("[DATABASE] Banco de dados iniciado com sucesso!")
	return true


func _load_maps() -> void:
	await _map_manager.load_all()
	await _map_collision_manager.load_all()
	await _map_warp_manager.load_all()


func _start_network(kind: Enums.TransportKind) -> bool:
	var transport: Transport.TransportServer = _create_transport(kind)
	if transport == null:
		return false

	var parts: PackedStringArray = Constants.ENDPOINT.split(":")
	if parts.size() != 2:
		push_error("[SERVER] Endpoint inválido: %s" % Constants.ENDPOINT)
		return false

	_network = Network.Server.new(
		parts[0],
		parts[1].to_int(),
		Constants.MAX_PEERS,
		transport
	)

	_network.client_connected.connect(_on_client_connected)
	_network.client_disconnected.connect(_on_client_disconnected)

	_setup_handlers()

	print("[SERVER] Iniciando servidor (%s) em %s..." % [
		str(Enums.TransportKind.find_key(kind)), Constants.ENDPOINT
	])

	var err: Error = _network.start()
	if err != OK:
		push_error("[SERVER] Erro ao iniciar o servidor (%s)." % error_string(err))
		return false

	print("[SERVER] Servidor iniciado com sucesso!")
	return true


func _setup_repositories() -> void:
	_account_repository = AccountRepository.new()
	await _account_repository.setup(_database)

	_map_repository = MapRepository.new()
	await _map_repository.setup(_database)

	_map_collision_repository = MapCollisionRepository.new()
	await _map_collision_repository.setup(_database)

	_map_warp_repository = MapWarpRepository.new()
	await _map_warp_repository.setup(_database)

	_character_repository = CharacterRepository.new()
	await _character_repository.setup(_database)


func _setup_managers() -> void:
	_account_manager = AccountManager.new(_account_repository)
	_map_manager = MapManager.new(_map_repository)
	_map_collision_manager = MapCollisionManager.new(_map_manager, _map_collision_repository)
	_map_warp_manager = MapWarpManager.new(_map_manager, _map_warp_repository)
	_character_manager = CharacterManager.new(_character_repository)


func _setup_handlers() -> void:
	_account_handler = AccountHandler.new(_network, _account_manager)
	_character_handler = CharacterHandler.new(_network, _account_manager, _character_manager)


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


func _release(peer_id: int) -> void:
	var character: Character = _character_manager.by_peer(peer_id)
	if character != null:
		_map_manager.leave(peer_id, character)

	await _character_manager.remove(peer_id)
	_account_manager.remove(peer_id)


func _shutdown() -> void:
	if _character_manager == null:
		return

	for peer_id: int in _character_manager.peers():
		await _release(peer_id)


func _on_client_connected(peer_id: int) -> void:
	print("[SERVER] Cliente %d conectado." % peer_id)


func _on_client_disconnected(peer_id: int) -> void:
	print("[SERVER] Cliente %d desconectado." % peer_id)

	await _release(peer_id)
