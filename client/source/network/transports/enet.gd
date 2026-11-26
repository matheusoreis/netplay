class_name EnetTransport
extends RefCounted


class EnetTransportClient extends Transport.TransportClient:
	const MAX_EVENTS_PER_TICK: int = 64

	var _enet_host: ENetConnection
	var _peer: ENetPacketPeer


	func connect_to_server(host: String, port: int) -> void:
		_enet_host = ENetConnection.new()
		_enet_host.create_host(1)
		_peer = _enet_host.connect_to_host(host, port)


	func close() -> void:
		_peer.peer_disconnect_later()
		await disconnected
		_enet_host.destroy()
		_enet_host = null
		closed.emit()


	func send(buf: PackedByteArray) -> void:
		_peer.send(0, buf, ENetPacketPeer.FLAG_RELIABLE)


	func poll(_dt: float) -> void:
		for i: int in MAX_EVENTS_PER_TICK:
			if _enet_host == null:
				return

			var ev: Array = _enet_host.service()

			match ev[0] as ENetConnection.EventType:
				ENetConnection.EventType.EVENT_NONE:
					return
				ENetConnection.EventType.EVENT_ERROR:
					error.emit()
				ENetConnection.EventType.EVENT_CONNECT:
					_peer = ev[1] as ENetPacketPeer
					connected.emit()
				ENetConnection.EventType.EVENT_DISCONNECT:
					_peer = null
					disconnected.emit()
				ENetConnection.EventType.EVENT_RECEIVE:
					var packet: PackedByteArray = (ev[1] as ENetPacketPeer).get_packet()
					packet_received.emit(packet)


class EnetTransportServer extends Transport.TransportServer:
	const MAX_EVENTS_PER_TICK: int = 64

	var _enet_host: ENetConnection
	var _peers: Dictionary[int, ENetPacketPeer] = {}
	var _next_id: int = 1


	func open(host: String, port: int, max_clients: int) -> Error:
		_enet_host = ENetConnection.new()
		return _enet_host.create_host_bound(host, port, max_clients)


	func poll(_dt: float) -> void:
		for i: int in MAX_EVENTS_PER_TICK:
			if _enet_host == null:
				return

			var ev: Array = _enet_host.service()

			match ev[0] as ENetConnection.EventType:
				ENetConnection.EventType.EVENT_NONE:
					return
				ENetConnection.EventType.EVENT_ERROR:
					error.emit()
				ENetConnection.EventType.EVENT_CONNECT:
					var peer: ENetPacketPeer = ev[1] as ENetPacketPeer
					var id: int = _next_id
					_next_id += 1
					peer.set_meta('conn_id', id)
					_peers[id] = peer
					client_connected.emit(id)
				ENetConnection.EventType.EVENT_DISCONNECT:
					var peer: ENetPacketPeer = ev[1] as ENetPacketPeer
					var id: int = peer.get_meta('conn_id', -1) as int
					if _peers.has(id):
						_peers.erase(id)
						client_disconnected.emit(id)
				ENetConnection.EventType.EVENT_RECEIVE:
					var peer: ENetPacketPeer = ev[1] as ENetPacketPeer
					var packet: PackedByteArray = peer.get_packet()
					var id: int = peer.get_meta('conn_id', -1) as int
					if _peers.has(id):
						packet_received.emit(id, packet)


	func send_to(target: Variant, buf: PackedByteArray) -> void:
		match typeof(target):
			TYPE_INT:
				var peer: ENetPacketPeer = _peers.get(target as int) as ENetPacketPeer
				if peer != null:
					peer.send(0, buf, ENetPacketPeer.FLAG_RELIABLE)
			TYPE_CALLABLE:
				var predicate: Callable = target as Callable
				for id: int in _peers:
					if predicate.call(id):
						_peers[id].send(0, buf, ENetPacketPeer.FLAG_RELIABLE)
			TYPE_ARRAY:
				var ids: Array = target as Array
				for id: int in ids:
					var peer: ENetPacketPeer = _peers.get(id) as ENetPacketPeer
					if peer != null:
						peer.send(0, buf, ENetPacketPeer.FLAG_RELIABLE)


	func kick(id: int) -> void:
		var peer: ENetPacketPeer = _peers.get(id) as ENetPacketPeer
		if peer == null: return

		_peers.erase(id)
		peer.peer_disconnect_now()
		client_disconnected.emit(id)


	func close() -> void:
		if _enet_host == null:
			return

		_enet_host.flush()
		_enet_host.destroy()
		_enet_host = null
		_peers.clear()
		closed.emit()
