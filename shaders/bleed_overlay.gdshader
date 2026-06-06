// bleed_overlay.gdshader
// Tints the screen toward the Act 2 "Bleed" palette — a foreshadow of the
// destroyed-world color grading. Applied as an additive semi-transparent overlay.
// Tweak bleed_color when real art assets replace the placeholder palette.
shader_type canvas_item;

/// The color cast of the Bleed — placeholder act-2 palette (desaturated, earthy ruin).
uniform vec4 bleed_color : source_color = vec4(0.18, 0.22, 0.12, 1.0);
/// 0.0 = invisible, 1.0 = full tint.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    COLOR = vec4(bleed_color.rgb, bleed_color.a * intensity);
}
