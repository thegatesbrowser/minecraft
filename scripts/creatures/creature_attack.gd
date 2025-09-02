extends State

var target:Player = null

@export var creature : CreatureBase

var attacked:bool = false

func Enter(data:Dictionary):
	attacked = false
	if data.has("player"):
		target = data.player
		print(data.player.name)
	
func Physics_Update(delta:float):
	if not target: 
		Transitioned.emit(self,"Idle",{})
		return
	
	creature.velocity = lerp(creature.velocity,Vector3.ZERO,.2)
	var distance:float = creature.global_position.distance_to(target.global_position)
	
	if distance < 1:
		if attacked == false:
			attacked = true
			await get_tree().create_timer(2.0).timeout
			target.rpc_id(target.get_multiplayer_authority(),"hit",creature.creature_resource.damage)
			
		else:
			Transitioned.emit(self,"Idle",{})
	else:
		Transitioned.emit(self,"Idle",{})
		
	print("distance ",distance)
