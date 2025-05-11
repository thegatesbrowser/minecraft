shader_type spatial;
render_mode cull_disabled;

uniform sampler2D grass_texture : filter_nearest, source_color;
uniform float distance_fade_min : hint_range(0.0, 4096.0, 0.01);
uniform float distance_fade_max : hint_range(0.0, 4096.0, 0.01);

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
//
	//// Distance Fade: Pixel Dither
	  //float fade_distance = length(VERTEX);
//
	  //// Use interleaved gradient noise, which is fast but still looks good.
	  //const vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
	  //float fade = clamp(smoothstep(distance_fade_min, distance_fade_max, fade_distance), 0.0, 1.0);
	  //// Use a hard cap to prevent a few stray pixels from remaining when past the fade-out distance.
	  //if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
	    //discard;
  //}
}
//
//
//
