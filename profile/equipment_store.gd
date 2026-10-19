extends RefCounted
class_name EquipmentStore
## Recoverable Windows replacement: flushed temp, last-good backup, then rename.

var path: String = "user://equipment.json"
var last_error: String = ""
var recovered: bool = false

func load_profile() -> EquipmentProfile:
	last_error = ""
	recovered = false
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak"):
		return EquipmentProfile.new()
	var result := _read(path)
	if result != null:
		return result
	result = _read(path + ".bak")
	if result != null:
		recovered = true
		return result
	last_error = "save_invalid"
	return null

func save_profile(profile: EquipmentProfile) -> String:
	if EquipmentProfile.decode(profile.snapshot()) == null:
		return "invalid_profile"
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return "save_open_failed"
	file.store_string(JSON.stringify(profile.snapshot()))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return "save_write_failed"
	# Never rotate a corrupt main over a known-good backup.
	if _read(path) != null:
		var backup_error: Error = DirAccess.copy_absolute(path, path + ".bak")
		if backup_error != OK:
			return "save_backup_failed"
	var rename_error: Error = DirAccess.rename_absolute(path + ".tmp", path)
	return "" if rename_error == OK else "save_replace_failed"

func _read(source: String) -> EquipmentProfile:
	if not FileAccess.file_exists(source):
		return null
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null:
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	return EquipmentProfile.decode(parser.data)
