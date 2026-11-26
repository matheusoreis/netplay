extends RefCounted
class_name Transport


class TransportClient extends Transport:
	@warning_ignore("unused_signal")
	signal connected()
	@warning_ignore("unused_signal")
	signal disconnected()
	@warning_ignore("unused_signal")
	signal packet_received(packet_buf: PackedByteArray)
	@warning_ignore("unused_signal")
	signal error()
	@warning_ignore("unused_signal")
	signal closed()


	func connect_to_server(_host: String, _port: int) -> void:
		pass


	func poll(_dt: float) -> void:
		pass


	func send(_buf: PackedByteArray) -> void:
		pass


	func close() -> void:
		pass


class TransportServer extends Transport:
	@warning_ignore("unused_signal")
	signal client_connected(id: int)
	@warning_ignore("unused_signal")
	signal client_disconnected(id: int)
	@warning_ignore("unused_signal")
	signal packet_received(id: int, packet_buf: PackedByteArray)
	@warning_ignore("unused_signal")
	signal error()
	@warning_ignore("unused_signal")
	signal closed()


	func open(_host: String, _port: int, _max_clients: int) -> Error:
		return OK


	func poll(_dt: float) -> void:
		pass


	func send_to(_target: Variant, _buf: PackedByteArray) -> void:
		pass


	func kick(_id: int) -> void:
		pass


	func close() -> void:
		pass
