extends RefCounted
class_name Handler


var _main: Main
var _network: Network.Client


func _init(main: Main, network: Network.Client) -> void:
	_main = main
	_network = network

	_register_handlers()


func _register_handlers() -> void:
	_network.register([])
