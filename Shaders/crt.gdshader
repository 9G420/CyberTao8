// ============================================================
// crt.gdshader - 微妙CRT效果 (Subtle CRT Effect)
// 参考风来之国(Eastward)风格：细扫描线+极轻暗角+微弱闪烁
// GL Compatibility兼容 - 纯覆盖层
// ============================================================
shader_type canvas_item;

// === 扫描线 (Scanlines) ===
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.06;
uniform float scanline_count : hint_range(60.0, 800.0) = 440.0;

// === 暗角 (Vignette) - 极轻微 ===
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.12;

// === 闪烁 (Flicker) - 几乎察觉不到 ===
uniform float flicker_intensity : hint_range(0.0, 0.05) = 0.008;

// === 整体开关 ===
uniform float master_intensity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    if (master_intensity <= 0.001) {
        COLOR = vec4(0.0);
    } else {

    vec2 uv = UV;
    float final_alpha = 0.0;

    // ─── 1. 细扫描线 (Fine scanlines) ───
    // 单层细线，模拟像素行间隙，不使用粗扫描线
    float scan = sin(uv.y * scanline_count * 6.28318) * 0.5 + 0.5;
    // 用smoothstep让扫描线更细更锐利
    float scanline = smoothstep(0.4, 0.6, scan);
    final_alpha += scanline_intensity * (1.0 - scanline);

    // ─── 2. 极轻暗角 (Very subtle vignette) ───
    // 纯黑暗角，不带颜色，只在最边缘微微变暗
    vec2 vig = uv * (1.0 - uv);
    float v = vig.x * vig.y * 25.0;
    v = clamp(pow(v, 0.8), 0.0, 1.0);
    float vig_alpha = (1.0 - v) * vignette_intensity;
    // 暗角只在最外圈，用pow压缩范围
    vig_alpha = vig_alpha * vig_alpha;
    final_alpha = max(final_alpha, vig_alpha);

    // ─── 3. 微弱亮度闪烁 (Barely perceptible flicker) ───
    float flicker = flicker_intensity * sin(TIME * 5.0 + sin(TIME * 13.0) * 0.5);
    final_alpha += flicker;

    // 最终：纯黑叠加，无颜色偏移
    final_alpha = clamp(final_alpha * master_intensity, 0.0, 0.25);
    COLOR = vec4(vec3(0.0), final_alpha);

    } // end else
}
