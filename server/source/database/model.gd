extends RefCounted
class_name Model


func from_row(row: Array, cols: PackedStringArray) -> void:
	for i in cols.size():
		set(cols[i], row[i])


func to_array() -> Array:
	return []
