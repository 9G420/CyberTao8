// ============================================================
// glitch.gdshader - 增强故障效果 (Enhanced Glitch Effect)
// 心魔反噬时启用 (Activated during "Inner Demon Backlash")
// EVA风格紫/血红/青配色 (EVA-style purple/blood-red/cyan)
// GL Compatibility兼容版 - 纯覆盖层，不采样屏幕纹理
// ============================================================
shader_type canvas_item;

// === 心魔反噬强度 (Inner Demon Backlash Intensity) ===
// 0=无故障, 1=最大反噬 (0=no glitch, 1=max backlash)
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;

// === 平滑过渡速度 (Smooth Transition Speed) ===
// 故障效果渐变速率 (Transition rate for glitch onset/decay)
uniform float transition_smoothness : hint_range(1.0, 20.0) = 6.0;

// === 色块参数 (Block Parameters) ===
// 色块大小 (Block displacement size)
uniform float block_size : hint_range(2.0, 64.0) = 20.0;
// 色块密度 (Block spawn density)
uniform float block_density : hint_range(0.0, 1.0) = 0.15;

// === 噪点参数 (Digital Noise Parameters) ===
uniform float noise_amount : hint_range(0.0, 1.0) = 0.15;
// 噪点粒度 (Noise grain size)
uniform float noise_grain : hint_range(20.0, 400.0) = 150.0;

// === 撕裂线参数 (Tear Line Parameters) ===
// 水平撕裂线数量 (Number of horizontal tear lines)
uniform float tear_count : hint_range(0.0, 30.0) = 8.0;
// 撕裂线强度 (Tear line intensity)
uniform float tear_intensity : hint_range(0.0, 1.0) = 0.5;

// === 闪白/闪红参数 (Flash Parameters) ===
// 闪烁概率缩放 (Flash probability scale)
uniform float flash_rate : hint_range(0.0, 0.2) = 0.07;

// === EVA配色 (EVA Color Palette) ===
// 紫色 (Purple - EVA Unit-01)
uniform vec3 eva_purple = vec3(0.45, 0.05, 0.85);
// 血红色 (Blood red - berserk/backlash)
uniform vec3 eva_red = vec3(0.9, 0.05, 0.15);
// 青色 (Cyan - digital/cyber)
uniform vec3 eva_cyan = vec3(0.0, 0.85, 0.95);

// ─── 伪随机工具函数 (Pseudo-random Utility Functions) ───
float random(vec2 st) {
    return fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123);
}

float random1(float n) {
    return fract(sin(n * 91.3458) * 47453.5453);
}

// 值噪声插值 (Value noise with interpolation)
float value_noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f); // smoothstep
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    // 强度为零时完全透明 (Fully transparent when no glitch)
    if (glitch_intensity <= 0.001) {
        COLOR = vec4(0.0);
    } else {

    vec2 uv = UV;

    // 平滑处理的有效强度 (Smoothed effective intensity)
    // 使用TIME进行平滑脉动，模拟不稳定的反噬 (Pulsing instability)
    float pulse = sin(TIME * transition_smoothness) * 0.15 + 0.85;
    float intensity = glitch_intensity * pulse;
    // 二次曲线让低强度更柔和 (Quadratic curve for softer low-intensity)
    float eff = intensity * intensity;

    // 时间量化，让故障有"帧"的感觉 (Quantized time for frame-like glitch feel)
    float t_fast = floor(TIME * 12.0);
    float t_mid = floor(TIME * 6.0);
    float t_slow = floor(TIME * 2.5);

    // 最终累积 (Final accumulation)
    vec3 col = vec3(0.0);
    float alpha = 0.0;

    // ─── 1. EVA风格色带条纹 (EVA-style Color Bands) ───
    // 横向扫描色带 (Horizontal scan color bands)
    float band_y = floor(uv.y * block_size);
    float band_rand = random(vec2(band_y, t_fast));
    if (band_rand < eff * 0.5) {
        // 三色随机选择 (Randomly pick from 3 EVA colors)
        float color_pick = random(vec2(t_fast, band_y * 7.0));
        vec3 band_col;
        if (color_pick < 0.33) {
            band_col = eva_purple;
        } else if (color_pick < 0.66) {
            band_col = eva_red;
        } else {
            band_col = eva_cyan;
        }
        // 色带内的横向渐变 (Horizontal gradient within band)
        float band_fade = smoothstep(0.0, 0.3, uv.x) * smoothstep(1.0, 0.7, uv.x);
        col = band_col * band_fade;
        alpha = eff * 0.45 * band_fade;
    }

    // ─── 2. 色块位移 (Block Displacement / Colored Rectangles) ───
    // 模拟数据块错位 (Simulate data block displacement)
    float bx = floor(uv.x * 10.0);
    float by = floor(uv.y * 8.0);
    float block_id = bx + by * 10.0;
    float block_rand = random(vec2(block_id, t_mid));
    if (block_rand < block_density * eff) {
        // 块的颜色和偏移 (Block color and offset)
        float block_color_r = random(vec2(t_mid * 3.0, block_id));
        vec3 block_col;
        if (block_color_r < 0.4) {
            block_col = eva_purple * 1.2;
        } else if (block_color_r < 0.7) {
            block_col = eva_red * 1.1;
        } else {
            block_col = eva_cyan * 1.3;
        }
        // 块内部微调亮度 (Brightness variation within block)
        float inner = random(vec2(block_id * 2.0, t_mid));
        block_col *= 0.7 + inner * 0.6;
        col = mix(col, block_col, 0.8);
        alpha = max(alpha, eff * 0.55);
    }

    // ─── 3. 数字噪点 (Digital Noise) ───
    // 高频像素噪点 (High-frequency pixel noise)
    float noise = random(uv * noise_grain + vec2(TIME * 60.0, TIME * 33.0));
    if (noise < noise_amount * eff) {
        // 噪点也用EVA配色 (Noise also uses EVA palette)
        float np = random(uv * 50.0 + TIME);
        vec3 noise_col = mix(eva_purple, eva_cyan, np) * 0.8;
        // 部分噪点为纯白增加数字感 (Some pure white noise for digital feel)
        if (np > 0.85) {
            noise_col = vec3(0.9);
        }
        col = mix(col, noise_col, 0.6);
        alpha = max(alpha, eff * 0.4);
    }

    // ─── 4. 水平撕裂线 (Horizontal Tear Lines) ───
    // 沿屏幕随机出现的水平亮线 (Random horizontal bright lines)
    for (int i = 0; i < 12; i++) {
        if (float(i) >= tear_count) break;
        float line_pos = random(vec2(float(i) * 13.7, t_slow + float(i)));
        // 撕裂线位置随时间跳变 (Tear line position jumps with time)
        float line_y = fract(line_pos + TIME * 0.3 * random(vec2(float(i), 0.0)));
        float line_dist = abs(uv.y - line_y);
        // 细线，宽度随强度变化 (Thin line, width scales with intensity)
        float line_width = 0.001 + eff * 0.003;
        float line_mask = smoothstep(line_width, 0.0, line_dist);
        if (line_mask > 0.01) {
            // 撕裂线用青色或白色 (Tear lines in cyan or white)
            vec3 tear_col = mix(eva_cyan, vec3(1.0), random(vec2(float(i), t_fast)));
            col = mix(col, tear_col, line_mask * tear_intensity * eff);
            alpha = max(alpha, line_mask * tear_intensity * eff * 0.7);
        }
    }

    // ─── 5. 闪白/闪红 (Flash White / Flash Red) ───
    // 全屏瞬间闪烁 (Full-screen instant flash)
    float flash_r = random(vec2(t_fast * 5.0, 1.23));
    if (flash_r < flash_rate * eff) {
        // 白闪或红闪随机 (Random white or red flash)
        float flash_type = random(vec2(t_fast * 7.0, 4.56));
        if (flash_type < 0.5) {
            // 闪白 (White flash)
            col = vec3(1.0);
            alpha = eff * 0.65;
        } else {
            // 闪红 - 心魔反噬标志色 (Red flash - backlash signature)
            col = eva_red * 1.5;
            alpha = eff * 0.7;
        }
    }

    // ─── 6. 高强度时的额外效果 (Extra Effects at High Intensity) ───
    // 心魔反噬加剧时，边缘渗出紫色 (Purple edge bleed at high backlash)
    if (intensity > 0.5) {
        float edge_x = smoothstep(0.0, 0.15, uv.x) * smoothstep(1.0, 0.85, uv.x);
        float edge_y = smoothstep(0.0, 0.15, uv.y) * smoothstep(1.0, 0.85, uv.y);
        float edge = 1.0 - edge_x * edge_y;
        float bleed = edge * (intensity - 0.5) * 2.0;
        // 交替紫色和血红 (Alternate purple and blood-red)
        vec3 bleed_col = mix(eva_purple, eva_red, sin(TIME * 3.0) * 0.5 + 0.5);
        col = mix(col, bleed_col, bleed * 0.5);
        alpha = max(alpha, bleed * 0.4);
    }

    // ─── 7. 极高强度全屏压迫 (Extreme intensity screen pressure) ───
    // 当心魔完全反噬，屏幕被血色笼罩 (Blood-color overtake at full backlash)
    if (intensity > 0.8) {
        float pressure = (intensity - 0.8) * 5.0; // 0-1 in range 0.8-1.0
        float throb = sin(TIME * 8.0) * 0.3 + 0.7; // 搏动感 (throbbing)
        col = mix(col, eva_red * 0.8, pressure * throb * 0.6);
        alpha = max(alpha, pressure * throb * 0.5);
    }

    // 最终输出 (Final output)
    alpha = clamp(alpha, 0.0, 0.9);
    COLOR = vec4(col, alpha);
    } // end else
}
