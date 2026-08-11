shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.4;
uniform float radius : hint_range(0.1, 1.5) = 0.85;
uniform float softness : hint_range(0.01, 1.5) = 0.6;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 2.0;
	float vig = smoothstep(radius, radius - softness, dist);
	COLOR = vec4(vignette_color.rgb, (1.0 - vig) * intensity);
}