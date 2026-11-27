extends RefCounted
class_name AccountManager


var _repository: AccountRepository

var _accounts: Dictionary[int, Account] = {}


func _init(repository: AccountRepository) -> void:
	_repository = repository


func by_peer(peer_id: int) -> Account:
	return _accounts.get(peer_id, null)


func all() -> Array[Account]:
	var result: Array[Account] = []
	result.assign(_accounts.values())
	return result


func has(peer_id: int) -> bool:
	return _accounts.has(peer_id)


func is_online(account_id: int) -> bool:
	for account: Account in _accounts.values():
		if account.id == account_id:
			return true

	return false


func remove(peer_id: int) -> void:
	_accounts.erase(peer_id)


func sign_in(peer_id: int, email: String, password: String) -> Array:
	if has(peer_id):
		return [ERR_ALREADY_IN_USE, "ALREADY_SIGNED_IN"]

	var check: Array = _validate(email, password)
	if check[0] != OK:
		return check

	var result: Array = await _repository.sign_in(email, password)
	if result[0] != OK:
		return result

	var model: AccountModel = result[1]

	if has(peer_id):
		return [ERR_ALREADY_IN_USE, "ALREADY_SIGNED_IN"]

	if is_online(model.id):
		return [ERR_ALREADY_IN_USE, "ACCOUNT_IN_USE"]

	_accounts[peer_id] = _hydrate(model)

	await _repository.update_access_at(model.id)

	return [OK, null]


func sign_up(peer_id: int, email: String, password: String) -> Array:
	var check: Array = _validate(email, password)
	if check[0] != OK:
		return check

	var result: Array = await _repository.sign_up(email, password)
	if result[0] != OK:
		return result

	return await sign_in(peer_id, email, password)


func _validate(email: String, password: String) -> Array:
	if not _is_email_valid(email):
		return [ERR_INVALID_PARAMETER, "INVALID_EMAIL"]

	if not _is_password_valid(password):
		return [ERR_INVALID_PARAMETER, "INVALID_PASSWORD"]

	return [OK, null]


func _is_email_valid(email: String) -> bool:
	return RegEx.create_from_string(
		Constants.EMAIL_REGEX
	).search(email) != null


func _is_password_valid(password: String) -> bool:
	return RegEx.create_from_string(
		Constants.PASSWORD_REGEX
	).search(password) != null


func _hydrate(model: AccountModel) -> Account:
	return Account.new(
		model.id,
		model.email,
		model.password,
		model.role,
		model.access_at,
		model.created_at,
		model.updated_at
	)
