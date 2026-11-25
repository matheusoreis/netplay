extends RefCounted
class_name Enums


enum TransportKind {
	FRAMED,
	ENET,
}

enum PacketKind {
	EXEC,
	INVOKE,
	RESULT,
}

enum CellFlag {
	NONE = 0,
	FULL_BLOCK = 1,
	UP = 2,
	RIGHT = 4,
	DOWN = 8,
	LEFT = 16,
}


enum Role {
	NONE,
	MODERATOR,
	ADMIN,
}
