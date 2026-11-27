extends Repository
class_name MapCollisionRepository


func _setup_schema() -> void:
	await _exec("""
		CREATE TABLE IF NOT EXISTS map_collisions (
			map_id INTEGER NOT NULL,
			cell_x INTEGER NOT NULL,
			cell_y INTEGER NOT NULL,
			flag INTEGER NOT NULL DEFAULT 0,

			PRIMARY KEY (map_id, cell_x, cell_y),

			FOREIGN KEY (map_id) REFERENCES maps(id) ON DELETE CASCADE
		)
	""")


func of_map(map_id: int) -> Array[MapCollisionModel]:
	var result: Array[MapCollisionModel] = []
	result.assign(await _rows(
		"SELECT * FROM map_collisions WHERE map_id = ?",
		[map_id],
		MapCollisionModel
	))

	return result


func insert(map_id: int, cell: Vector2i, flag: int) -> bool:
	return await _exec(
		"INSERT INTO map_collisions (map_id, cell_x, cell_y, flag) VALUES (?, ?, ?, ?)",
		[map_id, cell.x, cell.y, flag]
	) == OK


func delete_of_map(map_id: int) -> bool:
	return await _exec(
		"DELETE FROM map_collisions WHERE map_id = ?",
		[map_id]
	) == OK
