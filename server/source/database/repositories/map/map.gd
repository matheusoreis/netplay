extends Repository
class_name MapRepository


func _setup_schema() -> void:
	await _exec("""
		CREATE TABLE IF NOT EXISTS maps (
			id INTEGER PRIMARY KEY,
			identifier TEXT NOT NULL,
			bgm TEXT NOT NULL DEFAULT '',
			bgs TEXT NOT NULL DEFAULT '',
			size_x INTEGER NOT NULL DEFAULT 80,
			size_y INTEGER NOT NULL DEFAULT 34,
			created_at INTEGER NOT NULL DEFAULT 0,
			updated_at INTEGER NOT NULL DEFAULT 0
		)
	""")


func all() -> Array[MapModel]:
	var result: Array[MapModel] = []
	result.assign(await _rows(
		"SELECT * FROM maps ORDER BY id",
		[],
		MapModel
	))

	return result


func by_id(map_id: int) -> MapModel:
	return await _row(
		"SELECT * FROM maps WHERE id = ?",
		[map_id],
		MapModel
	)


func upsert(id: int, identifier: String, bgm: String, bgs: String, size: Vector2i) -> bool:
	var now: int = _now()
	var result: Error = await _exec("""
		INSERT INTO maps (id, identifier, bgm, bgs, size_x, size_y, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			identifier = excluded.identifier,
			bgm = excluded.bgm,
			bgs = excluded.bgs,
			size_x = excluded.size_x,
			size_y = excluded.size_y,
			updated_at = excluded.updated_at
	""", [id, identifier, bgm, bgs, size.x, size.y, now, now])

	return result == OK


func delete_except(ids: Array[int]) -> bool:
	if ids.is_empty():
		return await _exec("DELETE FROM maps", []) == OK

	var placeholders: PackedStringArray = PackedStringArray()
	for _index: int in ids.size():
		placeholders.append("?")

	return await _exec(
		"DELETE FROM maps WHERE id NOT IN (%s)" % ", ".join(placeholders),
		ids
	) == OK
