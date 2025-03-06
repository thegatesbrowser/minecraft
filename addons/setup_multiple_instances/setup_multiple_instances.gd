@tool
extends EditorPlugin

const menu_item_name = "Setup Multiple Instances and Restart"

const project_metadata_cfg = ".godot/editor/project_metadata.cfg"
const instance_1_arguments: Dictionary = {
	"arguments": "-- --server",
	"features": "dedicated_server", 
	"override_args": true,
	"override_features": true
}
const instance_2_arguments : Dictionary = {
	"arguments": "-- --print-logs",
	"features": "",
	"override_args": true,
	"override_features": false
}
const instance_3_arguments : Dictionary = {
	"arguments": "",
	"features": "",
	"override_args": true,
	"override_features": false
}


func _enter_tree():
	add_tool_menu_item(menu_item_name, _setup_instances)


func _exit_tree():
	remove_tool_menu_item(menu_item_name)


func _setup_instances():
	var config = ConfigFile.new()
	config.load(project_metadata_cfg)
	
	config.set_value("debug_options", "multiple_instances_enabled", true)
	config.set_value("debug_options", "run_instances_config", [
		instance_1_arguments,
		instance_2_arguments,
		instance_3_arguments
	])
	config.save(project_metadata_cfg)

	EditorInterface.restart_editor(true)
