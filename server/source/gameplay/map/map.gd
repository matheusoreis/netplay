extends RefCounted
class_name Map


var id: int
var identifier: String

var bgm: String
var bgs: String

var size: Vector2i

var collisions: Dictionary[Vector2i, int] = {}
var warps: Dictionary[Vector2i, Array] = {}

var characters: Dictionary[int, Character] = {}


func _init(
	id: int,
	identifier: String,
	bgm: String,
	bgs: String,
	size: Vector2i
) -> void:
	self.id = id
	self.identifier = identifier
	self.bgm = bgm
	self.bgs = bgs
	self.size = size


# Personagens

func add(peer_id: int, character: Character) -> void:
	characters[peer_id] = character


func remove(peer_id: int) -> void:
	characters.erase(peer_id)


func by_peer(peer_id: int) -> Character:
	return characters.get(peer_id, null)


func peers() -> Array[int]:
	var result: Array[int] = []
	result.assign(characters.keys())
	return result


func character_at(cell: Vector2i) -> Character:
	for character: Character in characters.values():
		if character.cell == cell:
			return character

	return null


func is_occupied(cell: Vector2i) -> bool:
	return character_at(cell) != null


# Colisões

func import_collisions(entries: Dictionary) -> void:
	collisions.assign(entries)


func set_collision(cell: Vector2i, flag: int) -> void:
	collisions[cell] = flag


func clear_collisions() -> void:
	collisions.clear()


func collision_flag(cell: Vector2i) -> int:
	return collisions.get(cell, Constants.CELL_NONE)


func is_solid(cell: Vector2i) -> bool:
	return (collision_flag(cell) & Constants.CELL_FULL_BLOCK) != 0


# Warps

func import_warps(entries: Dictionary) -> void:
	warps.assign(entries)


func set_warp(cell: Vector2i, entry: Array) -> void:
	warps[cell] = entry


func clear_warps() -> void:
	warps.clear()


func has_warp(cell: Vector2i) -> bool:
	return warps.has(cell)


func warp(cell: Vector2i) -> Array:
	return warps.get(cell, [])


# Espaço

func is_within_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < size.x and cell.y >= 0 and cell.y < size.y


func normalize_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(clampi(cell.x, 0, size.x - 1), clampi(cell.y, 0, size.y - 1))


func can_pass(from: Vector2i, direction: Vector2i) -> bool:
	var to: Vector2i = from + direction

	if not is_within_bounds(from) or not is_within_bounds(to):
		return false

	if is_solid(from) or is_solid(to):
		return false

	if (collision_flag(from) & _direction_to_flag(direction)) != 0:
		return false

	if (collision_flag(to) & _direction_to_flag(-direction)) != 0:
		return false

	if direction.x != 0 and direction.y != 0:
		if is_solid(Vector2i(from.x + direction.x, from.y)):
			return false

		if is_solid(Vector2i(from.x, from.y + direction.y)):
			return false

	return true


func can_place(cell: Vector2i) -> Array:
	if not is_within_bounds(cell):
		return [false, "OUT_OF_BOUNDS"]

	if is_solid(cell):
		return [false, "CELL_SOLID"]

	if is_occupied(cell):
		return [false, "CELL_OCCUPIED"]

	return [true, null]


func free_cell_near(cell: Vector2i) -> Array:
	for offset: Vector2i in Constants.NEAR_OFFSETS:
		var candidate: Vector2i = cell + offset
		if can_place(candidate)[0]:
			return [candidate, null]

	return [Vector2i.ZERO, "NO_FREE_SPOT_NEAR_TARGET"]


func _direction_to_flag(direction: Vector2i) -> int:
	match direction:
		Vector2i.DOWN:
			return Constants.CELL_DOWN
		Vector2i.LEFT:
			return Constants.CELL_LEFT
		Vector2i.RIGHT:
			return Constants.CELL_RIGHT
		Vector2i.UP:
			return Constants.CELL_UP
		_:
			return Constants.CELL_NONE
