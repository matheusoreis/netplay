extends RefCounted
class_name AccountManager


var _account_repository: AccountRepository

var _accounts: Dictionary[int, Account] = {}


func _init(account_repository: AccountRepository) -> void:
	_account_repository = account_repository


func account(peer_id: int) -> Account:
	return _accounts.get(peer_id)


func accounts() -> Array[Account]:
	var accounts: Array[Account] = []

	accounts.assign(
		_accounts.values()
	)

	return accounts


func has(peer_id: int) -> bool:
	return _accounts.has(peer_id)



func sign_in(peer_id: int, email: String, password: String) -> Array:
	if not _is_email_valid(email):
		return [ERR_INVALID_PARAMETER, "INVALID_EMAIL"]

	if not _is_password_valid(password):
		return [ERR_INVALID_PARAMETER, "INVALID_PASSWORD"]

	var sign_in_result: Array = await _account_repository.sign_in(email, password)
	if sign_in_result[0] != OK:
		return sign_in_result

	var model: AccountModel = sign_in_result[1]
	_accounts[peer_id] = _hydrate_account(model)

	await _account_repository.update_account_access_at(model.id)

	return [OK, ""]


func sign_up(peer_id: int, email: String, password: String) -> Array:
	if not _is_email_valid(email):
		return [ERR_INVALID_PARAMETER, "INVALID_EMAIL"]

	if not _is_password_valid(password):
		return [ERR_INVALID_PARAMETER, "INVALID_PASSWORD"]

	var sign_up_result: Array = await _account_repository.sign_up(email, password)
	if sign_up_result[0] != OK:
		return sign_up_result

	var sign_in_result: Array = await _account_repository.sign_in(email, password)
	if sign_in_result[0] != OK:
		return sign_in_result

	var model: AccountModel = sign_in_result[1]
	_accounts[peer_id] = _hydrate_account(model)

	await _account_repository.update_account_access_at(model.id)

	return [OK, ""]


func _hydrate_account(model: AccountModel) -> Account:
	return Account.new(
		model.id,
		model.email,
		model.password,
		model.role,
		model.access_at,
		model.created_at,
		model.updated_at
	)


func _is_email_valid(email: String) -> bool:
	return RegEx.create_from_string(
		Constants.EMAIL_REGEX
	).search(email) != null


func _is_password_valid(password: String) -> bool:
	return RegEx.create_from_string(
		Constants.PASSWORD_REGEX
	).search(password) != null
