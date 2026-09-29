shader_type canvas_item;
/* CRT + glitch + RGB kaymasi post-process katmani.
   master=0 -> hic efekt yok; 1 -> tam. Diger uniform'lar tur bazli yogunluk. */

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;
uniform float master : hint_range(0.0, 1.0) = 1.0;
uniform float scanlines : hint_range(0.0, 1.0) = 0.5;
uniform float rgb_shift : hint_range(0.0, 4.0) = 0.9;
uniform float glitch : hint_range(0.0, 1.0) = 0.12;
uniform float curvature : hint_range(0.0, 0.3) = 0.05;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// CRT egrilik: merkezden hafif bombe
	vec2 cc = uv - 0.5;
	uv = cc * (1.0 + dot(cc, cc) * curvature * master * 1.8) + 0.5;

	// glitch satir kaymasi — ara sira bir satir saga/sola kayar
	float row = floor(uv.y * 270.0);
	float slice = floor(TIME * 14.0);
	float r = rand(vec2(row, slice));
	if (r < glitch * master * 0.10) {
		uv.x += (rand(vec2(row, slice + 7.0)) - 0.5) * 0.07;
	}

	// sinir disi = siyah (CRT cam kivrimi)
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// RGB ayrismasi
		vec2 shift = vec2(rgb_shift * master, 0.0) * SCREEN_PIXEL_SIZE;
		vec3 col;
		col.r = texture(screen_tex, uv + shift).r;
		col.g = texture(screen_tex, uv).g;
		col.b = texture(screen_tex, uv - shift).b;

		// tarama cizgileri (270 satir)
		float scan = sin(uv.y * 270.0 * 3.14159265) * 0.5 + 0.5;
		col *= 1.0 - (scanlines * master) * (1.0 - scan) * 0.35;

		// vignette
		float vig = smoothstep(0.95, 0.35, length(cc));
		col *= mix(1.0, vig, vignette * master * 0.7);

		// hafif VHS parazit
		col += (rand(uv + TIME) - 0.5) * 0.03 * master;

		COLOR = vec4(col, 1.0);
	}
}
