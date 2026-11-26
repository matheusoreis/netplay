extends Control
class_name ConfirmationUi


var _callback_confirm: Callable
var _callback_cancel: Callable


func _ready() -> void:
	if not %Confirm.pressed.is_connected(_on_confirm_pressed):
		%Confirm.pressed.connect(_on_confirm_pressed)
	if not %Cancel.pressed.is_connected(_on_cancel_pressed):
		%Cancel.pressed.connect(_on_cancel_pressed)


func setup(
	message: String,
	callback_confirm: Callable,
	callback_cancel: Callable,
) -> void:
	%Message.text = tr(message)

	_callback_confirm = callback_confirm
	_callback_cancel = callback_cancel

	%Confirm.visible = callback_confirm.is_valid()
	%Cancel.visible = callback_cancel.is_valid()


func _on_confirm_pressed() -> void:
	var callback: Callable = _callback_confirm
	_callback_confirm = Callable()
	_callback_cancel = Callable()

	if callback.is_valid():
		callback.call()


func _on_cancel_pressed() -> void:
	var callback: Callable = _callback_cancel
	_callback_confirm = Callable()
	_callback_cancel = Callable()

	if callback.is_valid():
		callback.call()
