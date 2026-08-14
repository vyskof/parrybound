shader_type canvas_item;

uniform float shine_speed : hint_range(0.0, 2.0) = 0.4;
uniform float shine_strength : hint_range(0.0, 1.0) = 0.18;
uniform float tint_darken : hint_range(0.0, 0.5) = 0.12;
uniform vec4 tint_color : source_color = vec4(0.55, 0.65, 0.75, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 wet = mix(tex_color.rgb, tex_color.rgb * tint_color.rgb, tint_darken);

	float diag = (SCREEN_UV.x + SCREEN_UV.y) * 6.0;
	float shine = sin(diag - TIME * shine_speed * 6.0) * 0.5 + 0.5;
	shine = pow(shine, 8.0) * shine_strength;

	COLOR = vec4(wet + shine, tex_color.a);
}