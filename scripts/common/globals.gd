extends Node

# Debugging.
enum Level { DEBUG = 0, INFO = 1, WARNING = 2, ERROR = 3, CRITICAL = 4 }
@export var print_level := Logger.LogLevel.WARNING
@export var single_threaded_generate := false
@export var single_threaded_render := false
@export var capture_mouse_on_start := true

# Chunk Generation Settings.
@export var chunk_size := Vector3(16, 256, 16)
@export var max_stale_chunks := 2000

# Configurable setting based checked user's hardware.
@export var chunk_loading_threads := 7

@export var paused := false

var current_block:StringName ## unique_name
var custom_block:StringName ## unique_name
var can_build:bool = false
var view_range:int = 128


signal spawn_creature(pos,creature)
signal hunger_points_gained(amount)
signal add_object(data:Array)
signal removed_spawnpoint(id:Vector3)

# portals
signal open_portal_url(id:Vector3)
signal create_portal(id:Vector3)
signal enter_portal(url:String)
signal add_portal_url(id:Vector3,url:String)
signal remove_portal_data(id:Vector3)

# ui
signal new_ui(position:Vector3,instance_path:String)
signal sync_ui_change(index: int, item_path: String, amount: int,parent: String,health: int, rot:int)
#signal remove_ui(position:Vector3)

signal sync_add_metadata(pos,metadata)
signal sync_change_open(position,data,id)


signal open_inventory(id)
signal remove_item_from_hotbar

signal spawn_item_inventory(item)
signal spawn_item_hotbar(item)

signal check_amount_of_item(item)
signal remove_item(item,amount)
signal hotbar_slot_clicked(slot)
signal add_item_to_hand(item,scene:PackedScene)
signal remove_item_in_hand

signal craftable_hovered(craftable,node)
signal craftable_unhovered

signal drop_item(item)

signal start_hand_ani(ani_name)
signal stop_hand_ani()

# Backend
var client_id:String
signal save
signal save_slot(index: int, item_path: String, amount: int,parent: String,health: int)
signal send_to_server(data:Dictionary)
signal send_slot_data(data:Dictionary)


func _ready():
	Print.create_logger(0, print_level, Print.VERBOSE)
	

@rpc("any_peer","call_local")
func add_meta_data(pos:Vector3,data):
	TerrainHelper.get_terrain_tool().get_voxel_tool().set_voxel_metadata(pos,data)
	print("added meta at ",pos, " with ",data)

func find_item(item:ItemBase) -> Slot:
	var return_ = null
	
	var inventory = get_tree().get_first_node_in_group("Main Inventory")
	var hot_bar = get_tree().get_first_node_in_group("Hotbar")
	
	for slot in inventory.slots:
		if slot.item == item:
			return_ = slot
			break
	if return_ == null:
		for slot in hot_bar.buttons:
			if slot.item == item:
				return_ = slot
				break
	return return_
