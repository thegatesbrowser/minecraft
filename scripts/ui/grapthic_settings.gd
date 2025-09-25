extends PanelContainer

@export var enviorment:WorldEnvironment


func _on_fog_toggled(toggled_on: bool) -> void:
	enviorment.environment.volumetric_fog_enabled = toggled_on


func _on_glow_toggled(toggled_on: bool) -> void:
	enviorment.environment.glow_enabled = toggled_on


func _on_ssao_toggled(toggled_on: bool) -> void:
	enviorment.environment.ssao_enabled = toggled_on


func _on_view_range_text_submitted(new_text: String) -> void:
	Globals.view_range = new_text.to_int()


func _on_sdfgi_toggled(toggled_on: bool) -> void:
	enviorment.environment.sdfgi_enabled = toggled_on


func _on_taa_toggled(toggled_on: bool) -> void:
	RenderingServer.viewport_set_use_taa(get_tree().get_root().get_viewport_rid(),toggled_on)


func _on_transparency_toggled(toggled_on: bool) -> void:
	var terrian:VoxelTerrain = TerrainHelper.get_terrain_tool()
	var voxel_lib:VoxelBlockyTypeLibrary = terrian.mesher.library
	
	for voxel in voxel_lib.types:
		var mesh:VoxelBlockyType = voxel
		#print(mesh.unique_name)
		if mesh.base_model is VoxelBlockyModelCube:
			if mesh.base_model.get_material_override(0) is StandardMaterial3D:
				var mesh_material:StandardMaterial3D = mesh.base_model.get_material_override(0)
				if !toggled_on:
					mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				else:
					mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			
