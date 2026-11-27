extends Model
class_name MapModel


var id: int
var identifier: String
var bgm: String
var bgs: String
var size_x: int
var size_y: int
var created_at: int
var updated_at: int

func to_array() -> Array:
	return [
		id,
		identifier,
		bgm,
		bgs,
		size_x,
		size_y,
		created_at,
		updated_at
	]
