extends Model
class_name AccountModel


var id: int
var email: String
var password: String
var role: int
var access_at: int
var created_at: int
var updated_at: int


func to_array() -> Array:
	return [
		id,
		email,
		password,
		role,
		access_at,
		created_at,
		updated_at
	]
