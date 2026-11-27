extends Entity
class_name Character


var access_at: int
var created_at: int
var updated_at: int


func _init(
	id: int,
	identifier: String,
	spritesheet: String,
	map_id: int,
	cell: Vector2i,
	facing: Vector2i,
	access_at: int,
	created_at: int,
	updated_at: int,
) -> void:
	super(id, identifier, spritesheet, map_id, cell, facing)

	self.access_at = access_at
	self.created_at = created_at
	self.updated_at = updated_at


func warp(map_id: int, cell: Vector2i, facing: Vector2i) -> void:
	self.map_id = map_id
	self.cell = cell
	self.facing = facing
