extends RefCounted
class_name CharacterManager


var _repository: CharacterRepository

var _characters: Dictionary[int, Character] = {}


func _init(repository: CharacterRepository) -> void:
	_repository = repository


func by_peer(peer_id: int) -> Character:
	return _characters.get(peer_id, null)


func all() -> Array[Character]:
	var result: Array[Character] = []
	result.assign(_characters.values())
	return result


func has(peer_id: int) -> bool:
	return _characters.has(peer_id)


func remove(peer_id: int) -> void:
	_characters.erase(peer_id)


func peer_of(identifier: String) -> int:
	var lowered: String = identifier.to_lower()

	for peer_id: int in _characters:
		if _characters[peer_id].identifier.to_lower() == lowered:
			return peer_id

	return -1


func is_online(character_id: int) -> bool:
	for character: Character in _characters.values():
		if character.id == character_id:
			return true

	return false


func of_account(account_id: int) -> Array:
	var models: Array[CharacterModel] = await _repository.of_account(account_id)

	var result: Array[Character] = []
	result.assign(models.map(_hydrate))

	return [OK, result]


func create(account_id: int, identifier: String, spritesheet: String) -> Array:
	if not _is_identifier_valid(identifier):
		return [ERR_INVALID_PARAMETER, "INVALID_IDENTIFIER"]

	var result: Array = await _repository.create(account_id, identifier, spritesheet)
	if result[0] != OK:
		return result

	return [OK, _hydrate(result[1] as CharacterModel)]


func select(peer_id: int, account_id: int, character_id: int) -> Array:
	var check: Array = _validate(peer_id, character_id)
	if check[0] != OK:
		return check

	var result: Array = await _repository.select(character_id, account_id)
	if result[0] != OK:
		return result

	check = _validate(peer_id, character_id)
	if check[0] != OK:
		return check

	var character: Character = _hydrate(result[1] as CharacterModel)
	_characters[peer_id] = character

	return [OK, character]


func _validate(peer_id: int, character_id: int) -> Array:
	if has(peer_id):
		return [ERR_ALREADY_IN_USE, "CHARACTER_ALREADY_SELECTED"]

	if is_online(character_id):
		return [ERR_ALREADY_IN_USE, "CHARACTER_IN_USE"]

	return [OK, null]


func _is_identifier_valid(identifier: String) -> bool:
	return RegEx.create_from_string(
		Constants.IDENTIFIER_REGEX
	).search(identifier) != null


func _hydrate(model: CharacterModel) -> Character:
	return Character.new(
		model.id,
		model.identifier,
		model.spritesheet,
		model.map_id,
		Vector2i(model.cell_x, model.cell_y),
		Vector2i(model.facing_x, model.facing_y),
		model.access_at,
		model.created_at,
		model.updated_at
	)
