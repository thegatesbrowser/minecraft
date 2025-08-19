extends Control

@onready var loading_bar = $ProgressBar
@export var terrain:VoxelTerrain
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Console.add_command("hide_loading_screen", self, 'hide_loading_screen')\
		.set_description("Enables the player to clip through the world (or disables clipping).")\
		.register()
	pass # Replace with function body.

var isLoading:=true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var location = Vector3(12,50,8)

	var client = get_tree().get_first_node_in_group("BackendClient")

	if client:
		if !client.playerdata.is_empty():
			if client.playerdata.Position_x:
				#location = Vector3(client.playerdata.Position_x,client.playerdata.Position_y,client.playerdata.Position_z)
				pass
				
	var aabb:AABB = AABB(location,Vector3(40,60,40))
	if terrain.is_area_meshed(aabb):
		print("loaded")
		isLoading = false

	if isLoading == false:
		Globals.fnished_loading.emit()
		queue_free()


	if loading_bar.value < 100:
		loading_bar.value += delta * 10
	else:
		loading_bar.value = 0
	

func hide_loading_screen():
	visible = !visible