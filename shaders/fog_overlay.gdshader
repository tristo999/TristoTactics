// Animated fog / mist overlay.
// Renders drifting layers of procedural noise on top of the scene.
// Place BELOW the darkness rect in ScreenOverlay so fog is only visible
// inside the player's light circle.
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fog_color : source_color = vec4(0.55, 0.58, 0.65, 1.0);
uniform float speed : hint_range(0.0, 2.0) = 0.12;
uniform float scale : hint_range(0.1, 20.0) = 3.5;
uniform float density : hint_range(0.1, 5.0) = 1.8;

// --- Gradient noise ---
vec2 _hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float _noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(dot(_hash(i + vec2(0.0, 0.0)), f - vec2(0.0, 0.0)),
			dot(_hash(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0)), u.x),
		mix(dot(_hash(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0)),
			dot(_hash(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0)), u.x),
		u.y
	);
}

// Fractal Brownian Motion — stacks 5 octaves for natural-looking cloud shapes.
float _fbm(vec2 p) {
	float value = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amp * _noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV * scale;
	float t = TIME * speed;

	// Two fog layers drifting in different directions for parallax depth.
	float n1 = _fbm(uv + vec2(t * 0.6, t * 0.25));
	float n2 = _fbm(uv * 1.4 + vec2(-t * 0.35, t * 0.45) + 3.7);

	float fog = (n1 + n2) * 0.5 + 0.5; // remap -1..1 → 0..1
	fog = pow(fog, density);             // sharpen or soften edges

	COLOR = vec4(fog_color.rgb, fog * intensity);
}
