extends SceneTree
## Retired art pipeline. Use tools/prepare_toon_fx_131.py.
func _initialize() -> void:
	push_error("Retired VFX pipeline; run python3 tools/prepare_toon_fx_131.py")
	quit(1)
