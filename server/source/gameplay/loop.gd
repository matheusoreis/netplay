extends Node
class_name Loop


class Task:
	var interval: float
	var callback: Callable
	var generation: int


	func _init(interval: float, callback: Callable, generation: int) -> void:
		self.interval = interval
		self.callback = callback
		self.generation = generation


var _tasks: Dictionary[StringName, Task] = {}
var _generations: Dictionary[StringName, int] = {}


func add(identifier: StringName, interval: float, callback: Callable) -> void:
	remove(identifier)

	var generation: int = _generations.get(identifier, 0) + 1
	_generations[identifier] = generation

	_tasks[identifier] = Task.new(interval, callback, generation)
	_schedule(identifier)


func remove(identifier: StringName) -> void:
	_tasks.erase(identifier)

	_generations[identifier] = _generations.get(identifier, 0) + 1


func _schedule(identifier: StringName) -> void:
	var task: Task = _tasks.get(identifier)
	if task == null:
		return

	var timer: SceneTreeTimer = get_tree().create_timer(task.interval, false)
	timer.timeout.connect(_on_timeout.bind(identifier, task.generation))


func _on_timeout(identifier: StringName, generation: int) -> void:
	var task: Task = _tasks.get(identifier)
	if task == null or task.generation != generation:
		return

	task.callback.call(task.interval)
	_schedule(identifier)
