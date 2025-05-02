extends PanelContainer

@export var craftables:CraftableLibrary

@export var input_1:Slot 
@export var input_2:Slot

@export var output_slot:Slot

func _ready() -> void:
	input_1.item_changed.connect(check)
	input_2.item_changed.connect(check)
	
	output_slot.item_changed.connect(crafted)
	
func check(index:int,item_path:String,amount:int,parent:String,health:float,rot:int):
	var item1 = input_1.Item_resource
	var item2 = input_2.Item_resource


	if item1 != null and item2 == null:
		for craftable in craftables.craftable_array:
			var steps = craftable.items_needed.duplicate().size()
			if steps == 1:
				for i in craftable.items_needed:
					if craftable.items_needed[i].name == item1.unique_name:
						if input_1.amount >= craftable.items_needed[i].amount:
							craft(craftable)
							print("craft",craftable.Name)
							
	elif item2 != null and item1 == null:
		for craftable in craftables.craftable_array:
			var steps = craftable.items_needed.duplicate().size()
			if steps == 1:
				for i in craftable.items_needed:
					if craftable.items_needed[i].name == item2.unique_name:
						if input_2.amount >= craftable.items_needed[i].amount:
							craft(craftable)
							print("craft",craftable.Name)
							
	elif item2 != null and item1 != null:
		for craftable in craftables.craftable_array:
			var steps = craftable.items_needed.duplicate().size()
			if steps >= 2:
				for i in craftable.items_needed:
					if craftable.items_needed[i].name == item2.unique_name:
						if input_2.amount >= craftable.items_needed[i].amount:
							steps -= 1
					if craftable.items_needed[i].name == item1.unique_name:
						if input_1.amount >= craftable.items_needed[i].amount:
							steps -= 1
							
							
					if steps <= 0:
						craft(craftable)
						print("CRAFT",craftable.Name)
					
func craft(craftable:Craftable):
	output_slot.Item_resource = craftable.output_item

func crafted(index:int,item_path:String,amount:int,parent:String,health:float,rot:int):
	input_1.Item_resource = null
	input_2.Item_resource = null
	input_1.update_slot()
	input_2.update_slot()
