shader_type spatial;
render_mode cull_disabled;

uniform sampler2D grass_texture : filter_nearest, source_color;

void vertex(){
	NORMAL = vec3(0.0, 1.0, 0.0);
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * ( 1.0 - UV.y) * 0.2;
	VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * ( 1.0 - UV.y) * 0.15;
}

void fragment(){
	SPECULAR = 0.0;
	ALBEDO = texture(grass_texture, UV).rgb;
	ALPHA  = texture(grass_texture, UV).a;
	ALPHA_SCISSOR_THRESHOLD = .9;
}