extends Model
class_name MapWarpModel


var map_id: int
var cell_x: int
var cell_y: int
var to_map_id: int
var to_cell_x: int
var to_cell_y: int
var to_facing_x: int
var to_facing_y: int

func to_array() -> Array:
	return [
		map_id,
		cell_x,
		cell_y,
		to_map_id,
		to_cell_x,
		to_cell_y,
		to_facing_x,
		to_facing_y
	]
