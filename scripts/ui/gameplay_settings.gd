extends PanelContainer



func _on_headbob_toggled(toggled_on: bool) -> void:
	SettingsManager.headbob = toggled_on
	SettingsManager.updated.emit()

func _on_varing_fov_toggled(toggled_on: bool) -> void:
	SettingsManager.varing_fov = toggled_on
	SettingsManager.updated.emit()
