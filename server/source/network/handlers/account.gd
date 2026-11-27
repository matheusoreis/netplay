extends Handler
class_name AccountHandler


var _account_manager: AccountManager


func _init(network: Network.Server, account_manager: AccountManager) -> void:
	super(network)

	_account_manager = account_manager


func _register_handlers() -> void:
	_network.register([
		sign_in,
		sign_up
	])


func sign_in(email: String, password: String, major: int, minor: int, revision: int) -> void:
	var sender_id: int = _network.sender_id()

	if not _is_version_valid(major, minor, revision):
		return _network.exec(sender_id, &"sign_in", [false, "OUTDATED_CLIENT"])

	var result: Array = await _account_manager.sign_in(sender_id, email, password)
	if result[0] != OK:
		_network.exec(sender_id, &"sign_in", [false, result[1]])
		return

	var account: Account = _account_manager.by_peer(sender_id)
	_network.exec(sender_id, &"sign_in", [account.email, account.role])


func sign_up(email: String, password: String, major: int, minor: int, revision: int) -> void:
	var sender_id: int = _network.sender_id()

	if not _is_version_valid(major, minor, revision):
		return _network.exec(sender_id, &"sign_up", [false, "OUTDATED_CLIENT"])

	var result: Array = await _account_manager.sign_up(sender_id, email, password)
	if result[0] != OK:
		_network.exec(sender_id, &"sign_up", [false, result[1]])
		return

	var account: Account = _account_manager.by_peer(sender_id)
	_network.exec(sender_id, &"sign_up", [account.email, account.role])


func _is_version_valid(major: int, minor: int, revision: int) -> bool:
	return (
		major == Constants.MAJOR_VERSION
		and minor == Constants.MINOR_VERSION
		and revision == Constants.REVISION_VERSION
	)
