extends ItemBase
class_name ItemWeapon

@export var damage: int
@export var weapon_model: PackedScene
@export var needs_ammo: bool

@export var ammo_name: StringName = "Ammo"
@export var shoots: bool
@export var fire_rate: float
