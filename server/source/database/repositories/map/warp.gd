extends Repository
class_name MapWarpRepository


func _setup_schema() -> void:
	await _exec("""
		CREATE TABLE IF NOT EXISTS map_warps (
			map_id INTEGER NOT NULL,
			cell_x INTEGER NOT NULL,
			cell_y INTEGER NOT NULL,
			to_map_id INTEGER NOT NULL,
			to_cell_x INTEGER NOT NULL,
			to_cell_y INTEGER NOT NULL,
			to_facing_x INTEGER NOT NULL,
			to_facing_y INTEGER NOT NULL,

			PRIMARY KEY (map_id, cell_x, cell_y),

			FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE,
			FOREIGN KEY (to_map_id) REFERENCES maps(id) ON DELETE CASCADE
		)
	""")

	await _exec("""
		CREATE INDEX IF NOT EXISTS idx_map_warps_to_map ON map_warps(to_map_id)
	""")


func of_map(map_id: int) -> Array[MapWarpModel]:
	var result: Array[MapWarpModel] = []
	result.assign(await _rows(
		"SELECT * FROM map_warps WHERE map_id = ?",
		[map_id],
		MapWarpModel
	))

	return result


func insert(map_id: int, from_cell: Vector2i, to_map_id: int, to_cell: Vector2i, to_facing: Vector2i) -> bool:
	return await _exec(
		"INSERT INTO map_warps (map_id, cell_x, cell_y, to_map_id, to_cell_x, to_cell_y, to_facing_x, to_facing_y) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
		[map_id, from_cell.x, from_cell.y, to_map_id, to_cell.x, to_cell.y, to_facing.x, to_facing.y]
	) == OK


func delete_of_map(map_id: int) -> bool:
	return await _exec(
		"DELETE FROM map_warps WHERE map_id = ?",
		[map_id]
	) == OK
