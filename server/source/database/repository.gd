extends RefCounted
class_name Repository


var _database: Database


func setup(database: Database) -> void:
	_database = database

	@warning_ignore("redundant_await")
	await _setup_schema()


func _setup_schema() -> void:
	pass


func _exec(query: String, params: Array = []) -> Error:
	return await _database.exec(query, params)


func _row(query: String, params: Array = [], ty: GDScript = null) -> Model:
	return await _database.row(query, params, ty)


func _rows(query: String, params: Array = [], ty: GDScript = null) -> Array[Model]:
	return await _database.rows(query, params, ty)


func _scalar(query: String, params: Array = []) -> Variant:
	return await _database.scalar(query, params)


func _exists(query: String, params: Array = []) -> bool:
	return await _scalar(query, params) != null


func _now() -> int:
	return _database.now()


func _delete_where(table: String, condition: String, params: Array = []) -> Error:
	return await _exec("DELETE FROM %s WHERE %s" % [table, condition], params)


func _delete_ids_except(table: String, ids: Array[int], extra_condition: String = "") -> bool:
	return await _database.delete_ids_except(table, ids, extra_condition)
