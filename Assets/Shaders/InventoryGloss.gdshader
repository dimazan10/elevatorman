shader_type canvas_item;

uniform vec2 mouse_pos = vec2(0.5, 0.5);
uniform sampler2D icon_texture;

void fragment() {
	vec4 icon = texture(icon_texture, UV);

	float gloss = 0.0;
	float highlight = 0.0;

	if (mouse_pos.x >= 0.0 && mouse_pos.y >= 0.0) {
		vec2 rel = UV - mouse_pos;
		rel.x *= 0.6;
		float dist = length(rel);
		gloss = exp(-dist * dist * 10.0);

		vec2 hdir = mouse_pos - vec2(0.5, 0.5);
		vec2 hpos = UV + hdir * 0.08;
		vec2 hrel = hpos - vec2(0.5, 0.5);
		hrel.x *= 0.4;
		float hdist = length(hrel);
		highlight = exp(-hdist * hdist * 6.0) * 0.15;
	}

	vec3 final_color = icon.rgb + vec3(1.0) * gloss * 0.35 + vec3(1.0) * highlight;
	COLOR = vec4(final_color, icon.a);
}
