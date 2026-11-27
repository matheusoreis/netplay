extends RefCounted
class_name MapWarpManager


var _maps: MapManager
var _repository: MapWarpRepository


func _init(maps: MapManager, repository: MapWarpRepository) -> void:
	_maps = maps
	_repository = repository


func load_all() -> void:
	for map: Map in _maps.all():
		await load_map(map)


func load_map(map: Map) -> void:
	var models: Array[MapWarpModel] = await _repository.of_map(map.id)
	map.import_warps(_hydrate(models))


func insert(map_id: int, from_cell: Vector2i, to_map_id: int, to_cell: Vector2i, to_facing: Vector2i) -> Array:
	var map: Map = _maps.by_id(map_id)
	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	from_cell = _normalized(map, from_cell)
	if not map.is_within_bounds(from_cell):
		return [ERR_INVALID_PARAMETER, "CELL_OUT_OF_BOUNDS"]

	to_cell = _normalized(map, to_cell)
	if not map.is_within_bounds(to_cell):
		return [ERR_INVALID_PARAMETER, "DESTINATION_OUT_OF_BOUNDS"]

	if not await _repository.insert(map_id, from_cell, to_map_id, to_cell, to_facing):
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.set_warp(from_cell, _entry(to_map_id, to_cell, to_facing))

	return [OK, null]


func delete_of_map(map_id: int) -> Array:
	var map: Map = _maps.by_id(map_id)
	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	if not await _repository.delete_of_map(map_id):
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.clear_warps()

	return [OK, null]


func import_data(map_id: int, data: Array) -> Array:
	var map: Map = _maps.by_id(map_id)
	if map == null:
		return [ERR_DOES_NOT_EXIST, "MAP_NOT_FOUND"]

	var parsed: Dictionary[Vector2i, Array] = {}

	for entry: Array in data:
		var from_cell: Vector2i = entry[0]
		var to_map: Map = _maps.by_id(entry[1])
		var to_cell: Vector2i = entry[2]

		if to_map == null:
			continue

		if map.is_within_bounds(from_cell) and to_map.is_within_bounds(to_cell):
			parsed[from_cell] = _entry(to_map.id, to_cell, entry[3])

	if not await _repository.delete_of_map(map_id):
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	for from_cell: Vector2i in parsed:
		var warp: Array = parsed[from_cell]

		var inserted: bool = await _repository.insert(
			map_id,
			from_cell,
			warp[0],
			Vector2i(warp[1], warp[2]),
			Vector2i(warp[3], warp[4])
		)
		if inserted:
			continue

		await load_map(map)
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	map.import_warps(parsed)

	return [OK, null]


func _normalized(map: Map, cell: Vector2i) -> Vector2i:
	if map.is_within_bounds(cell):
		return cell

	return map.normalize_cell(cell)


func _entry(to_map_id: int, to_cell: Vector2i, to_facing: Vector2i) -> Array:
	return [to_map_id, to_cell.x, to_cell.y, to_facing.x, to_facing.y]


func _hydrate(models: Array[MapWarpModel]) -> Dictionary[Vector2i, Array]:
	var result: Dictionary[Vector2i, Array] = {}

	for model: MapWarpModel in models:
		result[Vector2i(model.cell_x, model.cell_y)] = _entry(
			model.to_map_id,
			Vector2i(model.to_cell_x, model.to_cell_y),
			Vector2i(model.to_facing_x, model.to_facing_y)
		)

	return result
