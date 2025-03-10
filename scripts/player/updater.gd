extends Node

func _ready() -> void:
	Globals.view_range_changed.connect(change_view_range)
	
	
	
func change_view_range():
	var viewer = get_parent().find_child("VoxelViewer") as VoxelViewer
	if viewer != null:
		viewer.view_distance = Globals.view_range
