extends StaticBody3D

var inventory:Node
@onready var fire_rate: Timer = $fire_rate
@onready var model: MeshInstance3D = $model

@export var weapon_resource: ItemBase


func _ready() -> void:
	inventory = get_tree().get_first_node_in_group("Main Inventory")
	
	if weapon_resource.weapon_model is Mesh:
		model.mesh = weapon_resource.weapon_model
	elif weapon_resource.weapon_model is PackedScene:
		add_child(weapon_resource.weapon_model.instantiate())
		
	fire_rate.wait_time = weapon_resource.fire_rate


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Build"):
		fire_rate.start()
		
	if Input.is_action_just_released("Build"):
		fire_rate.stop()


func fire() -> void:
	if inventory.check_amount_of_item(weapon_resource.ammo_name) >= 1:
		
		## sends to player to get the direction of the camera
		Globals.spawn_bullet.emit()
		
		inventory.remove_item(weapon_resource.ammo_name,1)
