shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tile_texture : filter_nearest;
uniform float tile_count : hint_range(1, 128) = 4.0;

void fragment() {
	vec2 tiled_uv = fract(UV * tile_count);
	COLOR = texture(tile_texture, tiled_uv);
}
