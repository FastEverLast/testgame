shader_type canvas_item;
render_mode blend_add;
uniform vec4 beam_color : source_color = vec4(1.0, 0.95, 0.7, 0.45);
uniform float levels = 5.0;
varying vec2 world_pos;
const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float beam = texture(TEXTURE, UV).a;
	vec2 cell = floor(world_pos);
	int index = int(mod(cell.y, 4.0)) * 4 + int(mod(cell.x, 4.0));
	float threshold = (BAYER[index] + 0.5) / 16.0;
	float stepped = floor(beam * levels + threshold) / levels;
	COLOR = vec4(beam_color.rgb, stepped * beam_color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
