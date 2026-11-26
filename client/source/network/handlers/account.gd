extends Handler
class_name AccountHandler


func _register_handlers() -> void:
	_network.register([
		sign_in,
		sign_up
	])


func sign_in() -> void:
	pass


func sign_up() -> void:
	pass
