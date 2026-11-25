extends Repository
class_name AccountRepository


func _setup_schema() -> void:
	await _exec("""
		CREATE TABLE IF NOT EXISTS accounts (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			email TEXT NOT NULL UNIQUE,
			password TEXT NOT NULL,
			role INTEGER NOT NULL DEFAULT 0,
			access_at INTEGER NOT NULL DEFAULT 0,
			created_at INTEGER NOT NULL DEFAULT 0,
			updated_at INTEGER NOT NULL DEFAULT 0
		)
	""")


func sign_in(email: String, password: String) -> Array:
	var model: AccountModel = await _row(
		"SELECT * FROM accounts WHERE email = ?",
		[email],
		AccountModel
	)

	if model == null:
		return [ERR_DOES_NOT_EXIST, "ACCOUNT_NOT_FOUND"]

	if not _verify_password(password, model.password):
		return [ERR_UNAUTHORIZED, "INCORRECT_PASSWORD"]

	return [OK, model]


func sign_up(email: String, password: String) -> Array:
	if await _exists("SELECT 1 FROM accounts WHERE email = ? LIMIT 1", [email]):
		return [ERR_ALREADY_EXISTS, "EMAIL_ALREADY_REGISTERED"]

	var now: int = _now()
	var result: Error = await _exec(
		"INSERT INTO accounts (email, password, access_at, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
		[email, _hash_password(password), now, now, now]
	)

	if result != OK:
		return [ERR_DATABASE_CANT_WRITE, "DATABASE_ERROR"]

	return [OK, null]


func update_access_at(account_id: int) -> void:
	await _exec(
		"UPDATE accounts SET access_at = ? WHERE id = ?",
		[_now(), account_id]
	)


func update_updated_at(account_id: int) -> void:
	await _exec(
		"UPDATE accounts SET updated_at = ? WHERE id = ?",
		[_now(), account_id]
	)


func _verify_password(password: String, stored_password: String) -> bool:
	return Sha256.new().verify_value(password, stored_password)


func _hash_password(password: String) -> String:
	return Sha256.new().hash_value(password)
