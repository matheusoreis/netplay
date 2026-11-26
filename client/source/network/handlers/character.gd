extends Handler
class_name CharacterHandler


func _register_handlers() -> void:
	_network.register([
		characters_of_account,
		create_character,
		delete_character,
		select_character
	])


func characters_of_account() -> void:
	pass


func create_character() -> void:
	pass


func delete_character() -> void:
	pass


func select_character() -> void:
	pass
