extends Control
class_name AlertUi


var _callback_confirm: Callable


func _ready() -> void:
	if not %Confirm.pressed.is_connected(_on_confirm_pressed):
		%Confirm.pressed.connect(_on_confirm_pressed)


func setup(message: String, callback_confirm: Callable) -> void:
	%Message.text = tr(message)
	_callback_confirm = callback_confirm

	%Confirm.visible = callback_confirm.is_valid()


func _on_confirm_pressed() -> void:
	var callback: Callable = _callback_confirm
	_callback_confirm = Callable()

	if callback.is_valid():
		callback.call()
