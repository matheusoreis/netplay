extends RefCounted
class_name Handler


var _network: Network.Server


func _init(network: Network.Server) -> void:
	_network = network


func register() -> void:
	_network.register([])


func unregister() -> void:
	_network.unregister([])
