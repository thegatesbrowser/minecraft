@tool
extends EditorPlugin


const PluginName = 'FpsCounter'
const PluginPath = 'res://addons/fps_counter/FpsCounter.tscn'


func _enter_tree():
	self.add_autoload_singleton(PluginName, PluginPath)


func _exit_tree():
	self.remove_autoload_singleton(PluginName)
