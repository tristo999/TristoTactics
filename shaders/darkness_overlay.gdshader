// darkens everything except a soft circle centered on the player.
// The player's Camera2D keeps them near screen-center, so light_center
// defaults to (0.5, 0.5) and rarely needs changing.
shader_type canvas_item;

/// Normalized [0,1] screen-space position of the light source.
uniform vec2 light_center = vec2(0.5, 0.5);
/// Radius of the lit circle, in normalized screen units.
uniform float radius : hint_range(0.0, 1.0) = 0.12;
/// Softness of the falloff edge.
uniform float softness : hint_range(0.0, 0.5) = 0.06;
/// Global darkness multiplier — 0.0 = transparent (no effect), 1.0 = full dark.
uniform float darkness : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    float dist = distance(SCREEN_UV, light_center);
    float hole = smoothstep(radius, radius + softness, dist);
    COLOR = vec4(0.0, 0.0, 0.0, hole * darkness);
}
