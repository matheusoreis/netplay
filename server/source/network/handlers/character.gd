extends Handler
class_name CharacterHandler


var _account_manager: AccountManager
var _character_manager: CharacterManager


func _init(network: Network.Server, account_manager: AccountManager, character_manager: CharacterManager) -> void:
	super(network)

	_account_manager = account_manager
	_character_manager = character_manager


func _register_handlers() -> void:
	_network.register([
		characters_of_account,
		create_character,
		delete_character,
		select_character
	])


func characters_of_account() -> void:
	var sender_id: int = _network.sender_id()

	var account: Account = _account_of(sender_id, &"list_characters")
	if account == null:
		return

	var result: Array = await _character_manager.of_account(account.id)
	if result[0] != OK:
		_network.exec(sender_id, &"list_characters", [false, result[1]])
		return

	_network.exec(sender_id, &"list_characters", [true, (result[1] as Array[Character]).map(
		func(character: Character) -> Array:
			return [character.id, character.identifier, character.spritesheet]
	)])


func create_character(identifier: String, spritesheet: String) -> void:
	var sender_id: int = _network.sender_id()

	var account: Account = _account_of(sender_id, &"create_character")
	if account == null:
		return

	var result: Array = await _character_manager.create(account.id, identifier, spritesheet)
	if result[0] != OK:
		_network.exec(sender_id, &"create_character", [false, result[1]])
		return

	_network.exec(sender_id, &"create_character", [true])


func delete_character(character_id: int) -> void:
	var sender_id: int = _network.sender_id()

	var account: Account = _account_of(sender_id, &"delete_character")
	if account == null:
		return

	var result: Array = await _character_manager.delete(account.id, character_id)
	if result[0] != OK:
		_network.exec(sender_id, &"delete_character", [false, result[1]])
		return

	_network.exec(sender_id, &"delete_character", [true])


func select_character(character_id: int) -> void:
	var sender_id: int = _network.sender_id()

	var account: Account = _account_of(sender_id, &"select_character")
	if account == null:
		return

	var result: Array = await _character_manager.select(sender_id, account.id, character_id)
	if result[0] != OK:
		_network.exec(sender_id, &"select_character", [false, result[1]])
		return

	var character: Character = result[1]

	_network.exec(sender_id, &"select_character", [
		true,
		character.id,
		character.identifier,
		character.spritesheet,
		character.map_id,
		character.cell,
		character.facing
	])


func _account_of(sender_id: int, reply: StringName) -> Account:
	var account: Account = _account_manager.by_peer(sender_id)
	if account == null:
		_network.exec(sender_id, reply, [false, "NOT_SIGNED_IN"])

	return account
