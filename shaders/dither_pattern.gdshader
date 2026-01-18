shader_type spatial;
render_mode unshaded;

uniform sampler2D pattern : filter_nearest;
uniform sampler2D albedo_texture : filter_nearest, hint_default_white;

uniform float tile_scale = 1.0;

const float DEFAULT_SCALE = 8.0;

void vertex() {
	UV=UV.xy;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 uv = FRAGCOORD.xy;
	vec2 tile_uv = uv / (DEFAULT_SCALE * tile_scale * -1.0);
	vec4 albedo = texture(albedo_texture, UV);
	vec4 pattern_texture = texture(pattern, tile_uv);

	ALBEDO = albedo.rgb;
	ALPHA = albedo.a * pattern_texture.a;
}