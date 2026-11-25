extends RefCounted
class_name CharacterManager


var _character_repository: CharacterRepository

var _characters: Dictionary[int, Character] = {}
var _characters_identifier_by_peer: Dictionary[String, int] = {}


func _init(character_repository: CharacterRepository) -> void:
	_character_repository = character_repository


func character(peer_id: int) -> Character:
	return _characters.get(peer_id)


func characters() -> Array[Character]:
	var characters: Array[Character] = []

	characters.assign(
		_characters.values()
	)

	return characters


func has(peer_id: int) -> bool:
	return _characters.has(peer_id)


func peer_of(identifier: String) -> int:
	return _characters_identifier_by_peer.get(identifier.to_lower())


func is_online(identifier: String) -> bool:
	return _characters_identifier_by_peer.has(identifier.to_lower())


func _hydrate_character(model: CharacterModel) -> Character:
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
