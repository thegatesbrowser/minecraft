extends Node

# Debugging.
enum Level { DEBUG = 0, INFO = 1, WARNING = 2, ERROR = 3, CRITICAL = 4 }
@export var print_level := Logger.LogLevel.WARNING
@export var single_threaded_generate := false
@export var single_threaded_render := false
@export var capture_mouse_on_start := true
@export var no_fog := false

# Chunk Generation Settings.
@export var world_seed := 333
@export var chunk_size := Vector3(16, 256, 16)
@export var load_radius := 16 # (int, 1, 64)
@export var max_stale_chunks := 2000
@export var chunk_type := 0
@export var skyblock := false

# Configurable setting based checked user's hardware.
@export var chunk_loading_threads := 7

# Player Settings.

## these are copys for ui puepose
var max_health:int
var player_health:int

@export var paused := false
@export var mouse_sensitivity := Vector2(0.3, 0.3)
@export var controller_sensitivity := Vector2(5, 2)
@export var max_look_vertical := 75
@export var controller_invert_look := false
@export var mouse_invert_look := false
@export var flying := false
var current_block := 0
var custom_block:Item_Global
var can_build:bool = false

# Automated Testing
@export var nav:bool = true
enum TestMode {NONE, STATIC_LOAD, RUN_LOAD, RUN_MANUAL}
@export var test_mode := TestMode.NONE
var settings_preset := ""
@export var repaint_line := true
@export var skip_menu := false
var test_file = null

# AI
signal spawn_creature(pos)

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

# Weapons
signal spawn_bullet

func _ready():
	Print.create_logger(0, print_level, Print.VERBOSE)
	randomize()
	if world_seed == 0:
		world_seed = randi()
	current_block = WorldGen.WOOD1
	
	Console.add_command("timelapse_mode", self, '_disable_flicker')\
		.set_description("Disables the chunk radar refresh line to prevent flickering in timelapses.")\
		.register()


func _disable_flicker():
	repaint_line = false


func slot_clicked(slot):
	if Globals.last_clicked_slot == null:
		Globals.last_clicked_slot = slot

	if slot == Globals.last_clicked_slot: return
	else:
		## move to blank
		if slot.Item_resource == null:
			print("move ")
			slot.Item_resource = Globals.last_clicked_slot.Item_resource
			slot.amount = Globals.last_clicked_slot.amount
			Globals.last_clicked_slot.Item_resource = null
			slot.update_slot()
			Globals.last_clicked_slot.update_slot()
			Globals.last_clicked_slot = null
		else:
			## stack
			if slot.Item_resource == Globals.last_clicked_slot.Item_resource:
				if slot.amount + Globals.last_clicked_slot.amount  < slot.Item_resource.max_stack:
					print("stack ")
					slot.amount += Globals.last_clicked_slot.amount
					Globals.last_clicked_slot.Item_resource = null
					Globals.last_clicked_slot.update_slot()
					Globals.last_clicked_slot = null
					slot.update_slot()
				
			## swap
			else:
				if slot.Item_resource != null:
					if slot.Item_resource != Globals.last_clicked_slot.Item_resource:
						print("swap " )
						var hold_slot_amount = slot.amount
						var hold_slot_resource = slot.Item_resource
						
						slot.Item_resource =  Globals.last_clicked_slot.Item_resource
						slot.amount = Globals.last_clicked_slot.amount
						
						Globals.last_clicked_slot.Item_resource = hold_slot_resource
						Globals.last_clicked_slot.amount = hold_slot_amount
						Globals.last_clicked_slot.update_slot()
						Globals.last_clicked_slot = null
						
						slot.update_slot()
