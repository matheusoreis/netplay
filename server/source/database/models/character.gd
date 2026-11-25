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
var role: int
var access_at: int
var created_at: int
var updated_at: int
var account_id: int


func to_array() -> Array:
	return [
		self.id,
		self.identifier,
		self.spritesheet,
		self.map_id,
		self.cell_x,
		self.cell_y,
		self.facing_x,
		self.facing_y,
		self.role,
		self.access_at,
		self.created_at,
		self.updated_at,
		self.account_id,
	]
