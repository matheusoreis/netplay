extends RefCounted
class_name MapManager


var _repository: MapRepository

var _maps: Dictionary[int, Map] = {}


func _init(repository: MapRepository) -> void:
	_repository = repository


func by_id(map_id: int) -> Map:
	return _maps.get(map_id, null)


func all() -> Array[Map]:
	var result: Array[Map] = []
	result.assign(_maps.values())
	return result


func has(map_id: int) -> bool:
	return _maps.has(map_id)


func count() -> int:
	return _maps.size()


func other_peers(map_id: int, except_id: int) -> Array[int]:
	var map: Map = by_id(map_id)
	if map == null:
		return []

	var result: Array[int] = map.peers()
	result.erase(except_id)
	return result


func load_all() -> void:
	reload(await _repository.all())


func reload(models: Array[MapModel]) -> void:
	var active: Dictionary[int, bool] = {}

	for model: MapModel in models:
		var map: Map = _maps.get(model.id, null)

		if map == null:
			map = _hydrate(model)
			_maps[map.id] = map
		else:
			map.identifier = model.identifier
			map.bgm = model.bgm
			map.bgs = model.bgs
			map.size = Vector2i(model.size_x, model.size_y)

		active[map.id] = true
		print("[MAP] Mapa %s carregado." % map.identifier)

	for id: int in _maps.keys():
		if active.has(id):
			continue

		if not _maps[id].characters.is_empty():
			continue

		_maps.erase(id)


func enter(peer_id: int, character: Character) -> Array:
	var map: Map = by_id(character.map_id)
	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	map.add(peer_id, character)

	return [OK, null]


func leave(peer_id: int, character: Character) -> void:
	var map: Map = by_id(character.map_id)
	if map != null:
		map.remove(peer_id)


func teleport(peer_id: int, character: Character, to_map_id: int, to_cell: Vector2i, to_facing: Vector2i = Vector2i.ZERO) -> Array:
	var to_map: Map = by_id(to_map_id)
	if to_map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	var check: Array = to_map.can_place(to_cell)
	if not check[0]:
		return [ERR_INVALID_PARAMETER, check[1]]

	if to_facing == Vector2i.ZERO:
		to_facing = character.facing

	if character.map_id != to_map_id:
		leave(peer_id, character)
		to_map.add(peer_id, character)

	character.warp(to_map_id, to_cell, to_facing)

	return [OK, null]


func teleport_near(peer_id: int, character: Character, anchor: Character) -> Array:
	var spot: Array = free_cell_near(anchor.map_id, anchor.cell)
	if spot[1] != null:
		return [ERR_UNAVAILABLE, spot[1]]

	return teleport(peer_id, character, anchor.map_id, spot[0])


func use_warp(peer_id: int, character: Character) -> Array:
	var map: Map = by_id(character.map_id)
	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	var entry: Array = map.warp(character.cell)
	if entry.is_empty():
		return [ERR_DOES_NOT_EXIST, "NO_WARP"]

	return teleport(
		peer_id,
		character,
		entry[0],
		Vector2i(entry[1], entry[2]),
		Vector2i(entry[3], entry[4])
	)


func free_cell_near(map_id: int, cell: Vector2i) -> Array:
	var map: Map = by_id(map_id)
	if map == null:
		return [Vector2i.ZERO, "MAP_NOT_FOUND"]

	return map.free_cell_near(cell)


func _hydrate(model: MapModel) -> Map:
	return Map.new(
		model.id,
		model.identifier,
		model.bgm,
		model.bgs,
		Vector2i(model.size_x, model.size_y)
	)
