extends RefCounted
class_name MapCollisionManager


var _maps: MapManager
var _repository: MapCollisionRepository


func _init(maps: MapManager, repository: MapCollisionRepository) -> void:
	_maps = maps
	_repository = repository


func load_all() -> void:
	for map: Map in _maps.all():
		await load_map(map)


func load_map(map: Map) -> void:
	var models: Array[MapCollisionModel] = await _repository.of_map(map.id)
	map.import_collisions(_hydrate(models))


func insert(map_id: int, cell: Vector2i, flag: int) -> Array:
	var map: Map = _maps.by_id(map_id)
	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	if not await _repository.insert(map_id, cell, flag):
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.set_collision(cell, flag)

	return [OK, null]


func delete_of_map(map_id: int) -> Array:
	var map: Map = _maps.by_id(map_id)
	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	if not await _repository.delete_of_map(map_id):
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.clear_collisions()

	return [OK, null]


func import_data(map_id: int, data: Array) -> Array:
	var map: Map = _maps.by_id(map_id)
	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	var parsed: Dictionary[Vector2i, int] = {}

	for entry: Array in data:
		var cell: Vector2i = entry[0]
		if map.is_within_bounds(cell):
			parsed[cell] = entry[1]

	if not await _repository.delete_of_map(map_id):
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	for cell: Vector2i in parsed:
		if await _repository.insert(map_id, cell, parsed[cell]):
			continue

		await load_map(map)
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.import_collisions(parsed)

	return [OK, null]


func _hydrate(models: Array[MapCollisionModel]) -> Dictionary[Vector2i, int]:
	var result: Dictionary[Vector2i, int] = {}

	for model: MapCollisionModel in models:
		result[Vector2i(model.cell_x, model.cell_y)] = model.flag

	return result
