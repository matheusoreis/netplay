extends Model
class_name CharacterModel


var id: int
var identifier: String
var spritesheet: String
var map_id: int
var cell_x: int
var cell_y: int
var facing_x: int
var facing_y: int
var access_at: int
var created_at: int
var updated_at: int
var account_id: int


func to_array() -> Array:
	return [
		id,
		identifier,
		spritesheet,
		map_id,
		cell_x,
		cell_y,
		facing_x,
		facing_y,
		access_at,
		created_at,
		updated_at,
		account_id,
	]
