extends Node


func _tween(subject:Node,tween_name:String,time:float,slide_to_pos:Vector2 = Vector2.ZERO):
	var tween = create_tween()
	if tween_name == "bounce":
		tween.tween_property(subject,"scale",Vector2(1.05,1.05),time/2)
		tween.tween_property(subject,"scale",Vector2(1,1),time/2)
	if tween_name == "bounce_in":
		subject.scale = Vector2(0,0)
		tween.tween_property(subject,"scale",Vector2(1.05,1.05),time/2)
		tween.tween_property(subject,"scale",Vector2(1,1),time/2)
	if tween_name == "bounce_out":
		tween.tween_property(subject,"scale",Vector2(1.05,1.05),time/2)
		tween.tween_property(subject,"scale",Vector2(0,0),time/2)
	if tween_name == "slide_out":
		tween.tween_property(subject,"position",slide_to_pos,time/2)
		
	if tween_name == "hurt":
		tween.tween_property(subject,"mo",slide_to_pos,time/2)
