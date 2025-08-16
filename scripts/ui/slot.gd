extends TextureButton
class_name Slot

signal item_changed(index:int,item_path:String,amount:int,parent:String,health:float,rot:int)

@export var locked:bool = false
@export var pressed_panel: Panel

@export var type: String = "inventory"
@export var amount: int = 1

@export var item: ItemBase
@export var background_texture:Texture

@export var rot_label:Label 
@onready var background_texturerect: TextureRect = $"CenterContainer/background texture"
@onready var image: TextureRect = $CenterContainer/Image
@onready var amount_label: Label = $amount
@onready var health_label: Label = $health
@onready var health_bar: ProgressBar = $CenterContainer/health

var max_rot:int = 0
var rot:int = 0
var index:int
var health:float
var played_ani:bool = false
var focused:bool = false


func _process(_delta: float) -> void: 
	if item != null:
		health_label.text = str(health)
		health_bar.value = health
		
		if item is ItemFood:
			if item.rot_step_textures.size() >= rot:
				if item.rot_step_textures.size() != 0:
					image.texture = item.rot_step_textures[rot]
			else:
				item = null
				update_slot()
		else:
			image.texture = item.texture
			
	else:
		image.texture = null
		
	amount_label.text = str(amount)
	
	if focused:
		if !played_ani:
			GlobalAnimation._tween(self,"bounce",.3)
			played_ani = true
		pressed_panel.show()
	else:
		played_ani = false
		pressed_panel.hide()
	
	# destorys the item is the amount is 0 (mainly for the furnace)
	if amount <= 0:
		amount = 1
		item = null
		image.texture = null
		amount_label.hide()
		
func _ready() -> void:
	background_texturerect.texture = background_texture
	index = get_index()
	
	if item != null:
		image.texture = item.texture
		
	if item is ItemFood:
		start_rot(item.time_rot_step)
	update_slot()


func _on_pressed() -> void:
	#print("pressed slot ",index)
	var slot_manager = get_node("/root/Main").find_child("SlotManager")
	
	if !locked:
		if Globals.paused:
			if type == "hotbar":
				if item != null:
					Globals.hotbar_slot_clicked.emit(self)
					
			
			if item != null:
				slot_manager.slot_clicked(self)
			else:
				if slot_manager.last_clicked_slot != null:
					slot_manager.slot_clicked(self)


func update_slot() -> void:
	amount_label.text = str(amount)
	if item != null:
		
		image.texture = item.texture

		if amount >= 2:
			amount_label.show()

		if item is ItemFood:
			max_rot = item.max_rot_steps
			rot_label.text = str(rot)
		else:
			stop_rot()

		item_changed.emit(index,item.get_path(),amount,get_parent().name,health,rot)
		
		if not item is ItemTool:
			health_bar.hide()
		else:
			health_bar.show()

	else:
		#print("item is null")
		amount = 1
		image.texture = null
		item_changed.emit(index,"",amount,get_parent().name,health,rot)
		health = 0
		health_bar.hide()
		rot_label.hide()
		amount_label.hide()
		

func used() -> void:
	#print("used slot ",index)
	health -= item.degrade_rate
	if health <= 0:
		item = null
	update_slot()
	
var _time
var timer:Timer

func start_rot(time:float) -> void:
	var rot_timer = Timer.new()
	rot_timer.wait_time = time
	rot_timer.name = "rot_timer"
	add_child(rot_timer)
	rot_timer.start()
	rot_timer.timeout.connect(rot_update)
	timer = rot_timer
	_time = time
	
func stop_rot() -> void:
	var rot_timer = find_child("rot_timer")
	if rot_timer != null:
		#print("stopping rot timer")
		rot_timer.stop()
		rot = 0
	
func rot_update() -> void:
	
	rot += 1
	if rot >= max_rot:
		item = null
	update_slot()
