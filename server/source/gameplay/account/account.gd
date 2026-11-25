extends RefCounted
class_name Account


var id: int
var email: String
var password: String
var role: int
var access_at: int
var created_at: int
var updated_at: int


func _init(
	id: int,
	email: String,
	password: String,
	role: int,
	access_at: int,
	created_at: int,
	updated_at: int
) -> void:
	self.id = id
	self.email = email
	self.password = password
	self.role = role
	self.access_at = access_at
	self.created_at = created_at
	self.updated_at = updated_at


func is_admin() -> bool:
	return role >= Constants.ROLE_ADMIN


func is_moderator() -> bool:
	return role >= Constants.ROLE_MODERATOR
