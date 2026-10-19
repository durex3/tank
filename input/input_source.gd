extends Node
class_name InputSource
## Device adapters override sample and cancel_pending; battle never reads Input.

func sample(tick: int) -> PlayerCommand:
	var command := PlayerCommand.new()
	command.client_tick = tick
	return command

func cancel_pending() -> void:
	pass
