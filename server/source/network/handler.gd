extends RefCounted
class_name Handler


var _network: Network.Server


func _init(network: Network.Server) -> void:
	_network = network

	_register_handlers()


func _register_handlers() -> void:
	_network.register([])
