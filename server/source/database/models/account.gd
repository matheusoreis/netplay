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
		self.id,
		self.email,
		self.password,
		self.role,
		self.access_at,
		self.created_at,
		self.updated_at
	]
