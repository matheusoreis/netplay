extends Repository
class_name CharacterRepository


func _setup_schema() -> void:
	await _exec("""
		CREATE TABLE IF NOT EXISTS characters (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			identifier TEXT NOT NULL,
			spritesheet TEXT NOT NULL,
			map_id INTEGER NOT NULL,
			cell_x INTEGER NOT NULL,
			cell_y INTEGER NOT NULL,
			facing_x INTEGER NOT NULL,
			facing_y INTEGER NOT NULL,
			access_at INTEGER NOT NULL DEFAULT 0,
			created_at INTEGER NOT NULL DEFAULT 0,
			updated_at INTEGER NOT NULL DEFAULT 0,
			account_id INTEGER NOT NULL,

			FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,

			UNIQUE (account_id, identifier)
		)
	""")

	await _exec("""
		CREATE INDEX IF NOT EXISTS idx_characters_account ON characters(account_id)
	""")


func of_account(account_id: int) -> Array[CharacterModel]:
	var result: Array[CharacterModel] = []
	result.assign(await _rows(
		"SELECT * FROM characters WHERE account_id = ? ORDER BY id",
		[account_id],
		CharacterModel
	))

	return result


func by_id(character_id: int) -> CharacterModel:
	return await _row(
		"SELECT * FROM characters WHERE id = ?",
		[character_id],
		CharacterModel
	)


func is_owner(character_id: int, account_id: int) -> bool:
	return await _exists(
		"SELECT 1 FROM characters WHERE id = ? AND account_id = ? LIMIT 1",
		[character_id, account_id]
	)


func identifier_exists(account_id: int, identifier: String) -> bool:
	return await _exists(
		"SELECT 1 FROM characters WHERE account_id = ? AND identifier = ? LIMIT 1",
		[account_id, identifier]
	)


func create(account_id: int, identifier: String, spritesheet: String) -> Array:
	if not Constants.AVAILABLE_SPRITES.has(spritesheet):
		return [ERR_INVALID_PARAMETER, "INVALID_SPRITE"]

	if await identifier_exists(account_id, identifier):
		return [ERR_ALREADY_EXISTS, "IDENTIFIER_ALREADY_EXISTS"]

	var now: int = _now()
	var result: Error = await _exec(
		"""
		INSERT INTO characters (
			identifier, account_id, spritesheet, map_id, cell_x, cell_y,
			facing_x, facing_y, created_at, updated_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		""",
		[
			identifier,
			account_id,
			spritesheet,
			Constants.START_MAP,
			Constants.START_MAP_POSITION.x,
			Constants.START_MAP_POSITION.y,
			Constants.START_MAP_FACING.x,
			Constants.START_MAP_FACING.y,
			now,
			now
		]
	)

	if result != OK:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	var model: CharacterModel = await _row(
		"SELECT * FROM characters WHERE account_id = ? AND identifier = ?",
		[account_id, identifier],
		CharacterModel
	)

	if model == null:
		return [ERR_DOES_NOT_EXIST, "DATABASE_ERROR"]

	return [OK, model]


func select(character_id: int, account_id: int) -> Array:
	var model: CharacterModel = await _row(
		"SELECT * FROM characters WHERE id = ? AND account_id = ?",
		[character_id, account_id],
		CharacterModel
	)

	if model == null:
		return [ERR_DOES_NOT_EXIST, "CHARACTER_NOT_FOUND"]

	return [OK, model]


func update_location(character_id: int, map_id: int, cell: Vector2i, facing: Vector2i) -> Array:
	var result: Error = await _exec(
		"UPDATE characters SET map_id = ?, cell_x = ?, cell_y = ?, facing_x = ?, facing_y = ?, updated_at = ? WHERE id = ?",
		[map_id, cell.x, cell.y, facing.x, facing.y, _now(), character_id]
	)

	if result != OK:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	return [OK, null]


func update_access_at(character_id: int) -> void:
	await _exec(
		"UPDATE characters SET access_at = ? WHERE id = ?",
		[_now(), character_id]
	)


func update_updated_at(character_id: int) -> void:
	await _exec(
		"UPDATE characters SET updated_at = ? WHERE id = ?",
		[_now(), character_id]
	)
