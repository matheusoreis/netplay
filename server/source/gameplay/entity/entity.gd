extends RefCounted
class_name Entity


var id: int
var identifier: String
var spritesheet: String
var map_id: int
var cell: Vector2i
var facing: Vector2i


func _init(
	id: int,
	identifier: String,
	spritesheet: String,
	map_id: int,
	cell: Vector2i,
	facing: Vector2i
) -> void:
	self.id = id
	self.identifier = identifier
	self.spritesheet = spritesheet
	self.map_id = map_id
	self.cell = cell
	self.facing = facing


func move(direction: Vector2i) -> void:
	self.facing = direction
	self.cell += direction
