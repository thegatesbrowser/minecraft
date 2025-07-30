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
@export var skyblock := false

# Configurable setting based checked user's hardware.
@export var chunk_loading_threads := 7

# Player Settings.
var breaking_efficiency:float = 0.0
var protection:int = 0
## these are copys for ui puepose
var max_health:int = 3
var player_health:int = 3

@export var paused := false
@export var mouse_sensitivity := Vector2(0.3, 0.3)
@export var controller_sensitivity := Vector2(5, 2)
@export var max_look_vertical := 75
@export var controller_invert_look := false
@export var mouse_invert_look := false
var current_block:StringName ## unique_name
var custom_block:StringName ## unique_name
var can_build:bool = false
var view_range:int = 128

signal spawn_creature(pos,creature)
signal hunger_points_gained(amount)
signal spawn_bullet
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
signal remove_ui(position:Vector3)
var last_clicked_slot:Node
var selected_slot:Slot ## the slot that is selected in the hotbar
signal sync_add_metadata(pos,metadata)
signal sync_change_open(position,data,id)

# inventory
var hotbar_full:bool = false

signal open_inventory(id)
signal add_subinventory(id)
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
var username:String
signal save
signal save_slot(index: int, item_path: String, amount: int,parent: String,health: int)
signal send_to_server(data:Dictionary)
signal send_slot_data(data:Dictionary)

var Inventory_holder:Inventory_Holder

func _ready():
	Print.create_logger(0, print_level, Print.VERBOSE)

func _process(delta: float) -> void:
	pass

func slot_clicked(slot:Slot):
	var soundmanager = get_node("/root/Main").find_child("SoundManager")
	soundmanager.play_UI_sound()
			
	if Globals.last_clicked_slot == null:
		Globals.last_clicked_slot = slot
		Globals.last_clicked_slot.focused = true

	if slot == Globals.last_clicked_slot: return
	else:
		## move to blank
		if slot.Item_resource == null:
			#print("move ")
			
			if slot.type == "chest_plate":
				if Globals.last_clicked_slot.Item_resource is ItemArmour:
					if Globals.last_clicked_slot.Item_resource.chest == false:
						return
				else:
					return
					
			if slot.type == "pants":
				if Globals.last_clicked_slot.Item_resource is ItemArmour:
					if Globals.last_clicked_slot.Item_resource.pants == false:
						return
				else:
					return
					
			if slot.type == "helment":
				if Globals.last_clicked_slot.Item_resource is ItemArmour:
					if Globals.last_clicked_slot.Item_resource.helment == false:
						return
				else:
					return
					
			slot.Item_resource = Globals.last_clicked_slot.Item_resource
			#slot.add_item.rpc(Globals.last_clicked_slot.Item_resource)
			slot.health = Globals.last_clicked_slot.health
			slot.amount = Globals.last_clicked_slot.amount
			slot.rot = Globals.last_clicked_slot.rot
			Globals.last_clicked_slot.Item_resource = null
			slot.update_slot()
			Globals.last_clicked_slot.update_slot()
			Globals.last_clicked_slot.focused = false
			Globals.last_clicked_slot = null
		else:
			## stack
			if slot.Item_resource == Globals.last_clicked_slot.Item_resource:
				if slot.amount + Globals.last_clicked_slot.amount  < slot.Item_resource.max_stack:
					#print("stack ")
					if slot.Item_resource is ItemFood:
						if Globals.last_clicked_slot.Item_resource is ItemFood:
							if Globals.last_clicked_slot.rot != slot.rot:
								return
								
					slot.amount += Globals.last_clicked_slot.amount
					Globals.last_clicked_slot.Item_resource = null
					Globals.last_clicked_slot.update_slot()
					Globals.last_clicked_slot.focused = false
					Globals.last_clicked_slot = null
					slot.update_slot()
				
			## swap
			else:
				if slot.Item_resource != null:
					if slot.Item_resource != Globals.last_clicked_slot.Item_resource:
						#print("swap " )
						
						if slot.type == "chest_plate":
							if Globals.last_clicked_slot.Item_resource is ItemArmour:
								if Globals.last_clicked_slot.Item_resource.chest == false:
									return
							else:
								return
							
						if slot.type == "pants":
							if Globals.last_clicked_slot.Item_resource is ItemArmour:
								if Globals.last_clicked_slot.Item_resource.pants == false:
									return
							else:
								return
							
						if slot.type == "helment":
							if Globals.last_clicked_slot.Item_resource is ItemArmour:
								if Globals.last_clicked_slot.Item_resource.helment == false:
									return
							else:
								return
							
						var hold_slot_health = slot.health
						var hold_slot_amount = slot.amount
						var hold_slot_rot = slot.rot
						var hold_slot_resource = slot.Item_resource
						
						slot.Item_resource = Globals.last_clicked_slot.Item_resource
						
						#slot.Item_resource =  Globals.last_clicked_slot.Item_resource
						slot.rot = Globals.last_clicked_slot.rot
						slot.amount = Globals.last_clicked_slot.amount
						slot.health = Globals.last_clicked_slot.health
						#Globals.last_clicked_slot.Item_resource = hold_slot_resource
						Globals.last_clicked_slot.Item_resource = hold_slot_resource
						
						Globals.last_clicked_slot.amount = hold_slot_amount
						Globals.last_clicked_slot.health = hold_slot_health
						Globals.last_clicked_slot.rot = hold_slot_rot
						Globals.last_clicked_slot.update_slot()
						Globals.last_clicked_slot.focused = false
						Globals.last_clicked_slot = null
						
						slot.update_slot()


func Spawn_creature(pos,creature):
	spawn_creature.emit(pos,creature)

func Add_water_fog(pos):
	#sync_water.rpc(pos)
	pass
	
func add_item_to_hotbar_or_inventory(item:ItemBase):
	if hotbar_full: spawn_item_inventory.emit(item)
	else:
		spawn_item_hotbar.emit(item)

@rpc("any_peer","call_local")
func add_meta_data(pos:Vector3,data):
	TerrainHelper.get_terrain_tool().get_voxel_tool().set_voxel_metadata(pos,data)
	print("added meta at ",pos, " with ",data)

@rpc("any_peer")
func live_ui(pos,data,id):
	Globals.sync_change_open.emit(pos,data,id)

func find_item(item:ItemBase) -> Slot:
	var return_ = null
	
	var inventory = get_tree().get_first_node_in_group("Main Inventory")
	var hot_bar = get_tree().get_first_node_in_group("Hotbar")
	
	for slot in inventory.slots:
		if slot.Item_resource == item:
			return_ = slot
			break
	if return_ == null:
		for slot in hot_bar.buttons:
			if slot.Item_resource == item:
				return_ = slot
				break
	return return_
