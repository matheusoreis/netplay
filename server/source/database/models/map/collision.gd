extends Model
class_name MapCollisionModel


var map_id: int
var cell_x: int
var cell_y: int
var flag: int


func to_array() -> Array:
	return [
		map_id,
		cell_x,
		cell_y,
		flag
	]
