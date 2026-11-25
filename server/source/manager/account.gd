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
