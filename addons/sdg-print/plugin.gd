@tool
extends EditorPlugin


const PluginName = 'Print'
const PluginPath = 'res://addons/sdg-print/Print.tscn'


func _enter_tree():
	self.add_autoload_singleton(PluginName, PluginPath)


func _exit_tree():
	self.remove_autoload_singleton(PluginName)
