extends Repository
class_name CharacterRepository


func _setup_schema() -> void:
	await _exec("""
		CREATE TABLE IF NOT EXISTS characters (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			identifier TEXT NOT NULL,
			spritesheet TEXT NOT NULL,
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
