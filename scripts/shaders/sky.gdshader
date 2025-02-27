shader_type sky;


uniform sampler2D gradient: hint_default_black;
uniform vec4 skyColor : source_color;

void sky() {
	COLOR = skyColor.rgb;
	// Called for every visible pixel in the sky background, as well as all pixels
	// in the radiance cubemap.
}
