extends Handler
class_name AccountHandler


func _register_handlers() -> void:
	_network.register([
		sign_in,
		sign_up
	])


func sign_in(email: String, password: String, major: int, minor: int, revision: int) -> void:
	var sender_id: int = _network.sender_id()

	if not _is_version_valid(major, minor, revision):
		return _network.exec(sender_id, &"sign_in", [false, "OUTDATED_CLIENT"])


func sign_up(email: String, password: String, major: int, minor: int, revision: int) -> void:
	var sender_id: int = _network.sender_id()

	if not _is_version_valid(major, minor, revision):
		return _network.exec(sender_id, &"sign_in", [false, "OUTDATED_CLIENT"])


func _is_version_valid(major: int, minor: int, revision: int) -> bool:
	return (
		major == Constants.MAJOR_VERSION
		and minor == Constants.MINOR_VERSION
		and revision == Constants.REVISION_VERSION
	)
