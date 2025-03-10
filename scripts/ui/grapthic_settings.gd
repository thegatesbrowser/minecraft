extends PanelContainer

@export var enviorment:WorldEnvironment



func _on_fog_toggled(toggled_on: bool) -> void:
	enviorment.environment.volumetric_fog_enabled = toggled_on


func _on_glow_toggled(toggled_on: bool) -> void:
	enviorment.environment.glow_enabled = toggled_on


func _on_ssao_toggled(toggled_on: bool) -> void:
	enviorment.environment.ssao_enabled = toggled_on


func _on_sdgi_toggled(toggled_on: bool) -> void:
	enviorment.environment.sdfgi_enabled = toggled_on


func _on_view_range_text_submitted(new_text: String) -> void:
	Globals.view_range = new_text.to_int()
	Globals.view_range_changed.emit()
