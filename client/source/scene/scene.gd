extends Node2D
class_name Scene


@export_category("Controls")
@export var _interfaces: Dictionary[StringName, Control]


func setup() -> void:
	pass


func get_interface(identifier: StringName) -> Control:
	return _interfaces.get(identifier, null)


func show_interface(identifier: StringName) -> void:
	var interface: Control = get_interface(identifier)
	if interface == null:
		return

	_release_interface_focus()
	interface.visible = true


func hide_interface(identifier: StringName) -> void:
	var interface: Control = get_interface(identifier)
	if interface == null:
		return

	interface.visible = false


func show_alert(message: String) -> void:
	var alert_ui: AlertUi = get_interface(&"Alert") as AlertUi
	if alert_ui == null:
		return

	alert_ui.setup(message, func() -> void: hide_interface(&"Alert"))

	show_interface(&"Alert")


func show_confirmation(
	message: String,
	callback_confirm: Callable,
	callback_cancel: Callable,
) -> void:
	var confirmation_ui: ConfirmationUi = get_interface(&"Confirmation") as ConfirmationUi
	if confirmation_ui == null:
		return

	var wrapped_confirm: Callable = func() -> void:
		hide_interface(&"Confirmation")
		callback_confirm.call()

	var wrapped_cancel: Callable = func() -> void:
		hide_interface(&"Confirmation")
		callback_cancel.call()

	confirmation_ui.setup(message, wrapped_confirm, wrapped_cancel)

	show_interface(&"Confirmation")


func _release_interface_focus() -> void:
	get_viewport().gui_release_focus()
