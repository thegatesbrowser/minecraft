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

# AI
signal spawn_creature(pos,creature)

# Inventory
signal open_inventory(Owner)
signal add_subinventory(Owner)

signal remove_item_from_hotbar
signal spawn_item_inventory(item)
signal check_amount_of_item(item)
signal remove_item(item,amount)
signal hotbar_slot_clicked(slot)
signal add_item_to_hand(item)
signal remove_item_in_hand
#signal slot_clicked(slot)
signal craftable_hovered(craftable,node)
signal craftable_unhovered
var last_clicked_slot:Node

var known_storage = []
#signal add_item_to_hand(item)
#signal remove_item_in_hand
#signal craftable_hovered(craftable,node)
#signal craftable_unhovered

# Weapons
signal spawn_bullet


func _ready():
	Print.create_logger(0, print_level, Print.VERBOSE)


func slot_clicked(slot):
	var soundmanager = get_node("/root/Main").find_child("SoundManager")
	soundmanager.play_UI_sound()
			
	if Globals.last_clicked_slot == null:
		Globals.last_clicked_slot = slot

	if slot == Globals.last_clicked_slot: return
	else:
		## move to blank
		if slot.Item_resource == null:
			#print("move ")
			slot.Item_resource = Globals.last_clicked_slot.Item_resource
			#slot.add_item.rpc(Globals.last_clicked_slot.Item_resource)
			slot.amount = Globals.last_clicked_slot.amount
			Globals.last_clicked_slot.Item_resource = null
			slot.update_slot()
			Globals.last_clicked_slot.update_slot()
			Globals.last_clicked_slot = null
		else:
			## stack
			if slot.Item_resource == Globals.last_clicked_slot.Item_resource:
				if slot.amount + Globals.last_clicked_slot.amount  < slot.Item_resource.max_stack:
					#print("stack ")
					slot.amount += Globals.last_clicked_slot.amount
					Globals.last_clicked_slot.Item_resource = null
					Globals.last_clicked_slot.update_slot()
					Globals.last_clicked_slot = null
					slot.update_slot()
				
			## swap
			else:
				if slot.Item_resource != null:
					if slot.Item_resource != Globals.last_clicked_slot.Item_resource:
						#print("swap " )
						var hold_slot_amount = slot.amount
						var hold_slot_resource = slot.Item_resource
						
						slot.Item_resource = Globals.last_clicked_slot.Item_resource
						#slot.Item_resource =  Globals.last_clicked_slot.Item_resource
						slot.amount = Globals.last_clicked_slot.amount
						
						#Globals.last_clicked_slot.Item_resource = hold_slot_resource
						Globals.last_clicked_slot.Item_resource = hold_slot_resource
						
						Globals.last_clicked_slot.amount = hold_slot_amount
						Globals.last_clicked_slot.update_slot()
						Globals.last_clicked_slot = null
						
						slot.update_slot()

func Spawn_creature(pos,creature):
	spawn_creature.emit(pos,creature)
