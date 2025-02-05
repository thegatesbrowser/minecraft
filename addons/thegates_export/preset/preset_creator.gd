@tool
class_name TGPresetCreator
extends Node

const PRESET_CFG = "res://addons/thegates_export/preset/preset.cfg"
const PROJECT_PRESET_CFG = "res://export_presets.cfg"

const PRESET_NAME: String = "TheGates"
const SECTION: String = "preset.0"
const SECTION_OPTIONS: String = "preset.0.options"

const NEW_SECTION: String = "preset.%d"
const NEW_SECTION_OPTIONS: String = "preset.%d.options"


func create_and_get_preset() -> String:
	if FileAccess.file_exists(PROJECT_PRESET_CFG):
		if not is_preset_added():
			add_preset()
	else:
		copy_preset()
	
	return PRESET_NAME


func copy_preset() -> void:
	DirAccess.copy_absolute(PRESET_CFG, PROJECT_PRESET_CFG)
	print("Export preset is copied")


func is_preset_added() -> bool:
	var cfg = ConfigFile.new()
	cfg.load(PROJECT_PRESET_CFG)
	
	var sections = cfg.get_sections()
	for section in sections:
		var keys = cfg.get_section_keys(section)
		if keys.has("name") and cfg.get_value(section, "name") == PRESET_NAME:
			return true
	
	return false


func add_preset() -> void:
	var proj_cfg = ConfigFile.new()
	var cfg = ConfigFile.new()
	
	proj_cfg.load(PROJECT_PRESET_CFG)
	cfg.load(PRESET_CFG)
	
	var new_index = get_new_index(proj_cfg)
	var new_section = NEW_SECTION % [new_index]
	var new_section_option = NEW_SECTION_OPTIONS % [new_index]
	
	var keys = cfg.get_section_keys(SECTION)
	for key in keys:
		var value = cfg.get_value(SECTION, key)
		proj_cfg.set_value(new_section, key, value)
	
	keys = cfg.get_section_keys(SECTION_OPTIONS)
	for key in keys:
		var value = cfg.get_value(SECTION_OPTIONS, key)
		proj_cfg.set_value(new_section_option, key, value)
	
	proj_cfg.save(PROJECT_PRESET_CFG)
	print("Export preset is added at ", new_index)


func get_new_index(proj_cfg: ConfigFile) -> int:
	var max_index = -1
	var sections = proj_cfg.get_sections()
	
	for section in sections:
		var index = section.split(".")[1]
		if index.is_valid_int():
			max_index = int(index)
	
	return max_index + 1
