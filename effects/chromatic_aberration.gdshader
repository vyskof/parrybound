shader_type canvas_item;

uniform float aberration_amount : hint_range(0.0, 0.05) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 dir = SCREEN_UV - vec2(0.5);
	vec2 offset = dir * aberration_amount;
	float r = texture(screen_texture, SCREEN_UV + offset).r;
	float g = texture(screen_texture, SCREEN_UV).g;
	float b = texture(screen_texture, SCREEN_UV - offset).b;
	float a = texture(screen_texture, SCREEN_UV).a;
	COLOR = vec4(r, g, b, a);
}