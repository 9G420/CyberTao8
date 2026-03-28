// ============================================================
// summon_aura.gdshader - 召唤物专属光环 (Summon Unit Aura)
// 柔和脉冲环形发光 + 道教符文纹路
// 6种色彩模式对应不同召唤物类型
// GL Compatibility 兼容
// ============================================================
shader_type canvas_item;

// 0=绿(精灵), 1=橙(狐/兽), 2=紫(龙/分身), 3=青(魔像/使魔), 4=白(鹤), 5=金(蜂群)
uniform int color_mode : hint_range(0, 5) = 0;
uniform float pulse_speed : hint_range(0.5, 6.0) = 2.0;
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float rune_visibility : hint_range(0.0, 1.0) = 0.4;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 center = UV - vec2(0.5);
    float dist = length(center);
    float angle = atan(center.y, center.x);

    // --- 基础环形遮罩 ---
    float ring_outer = smoothstep(0.5, 0.42, dist);
    float ring_inner = smoothstep(0.25, 0.32, dist);
    float ring = ring_outer * ring_inner;

    // 柔和填充（中心淡光）
    float fill = (1.0 - smoothstep(0.0, 0.45, dist)) * 0.15;

    // --- 脉冲 ---
    float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
    float pulse2 = 0.8 + 0.2 * sin(TIME * pulse_speed * 1.7 + 1.0);

    // --- 道教符文纹路（8等分角度上的短线段标记）---
    float rune_pattern = 0.0;
    for (int i = 0; i < 8; i++) {
        float target_angle = float(i) * 6.2831 / 8.0 + TIME * 0.3;
        float angle_diff = abs(mod(angle - target_angle + 3.14159, 6.2831) - 3.14159);
        float on_line = smoothstep(0.15, 0.05, angle_diff);
        float in_ring = smoothstep(0.32, 0.35, dist) * (1.0 - smoothstep(0.42, 0.45, dist));
        rune_pattern += on_line * in_ring;
    }
    rune_pattern = min(rune_pattern, 1.0) * rune_visibility;

    // --- 颜色选择 ---
    vec3 base_color;
    if (color_mode == 0) {
        base_color = vec3(0.22, 1.0, 0.08); // 霓虹绿
    } else if (color_mode == 1) {
        base_color = vec3(1.0, 0.5, 0.0);   // EVA橙
    } else if (color_mode == 2) {
        base_color = vec3(0.54, 0.12, 0.8);  // 电紫
    } else if (color_mode == 3) {
        base_color = vec3(0.0, 0.9, 1.0);    // 赛博青
    } else if (color_mode == 4) {
        base_color = vec3(0.94, 0.91, 0.82); // 符纸白
    } else {
        base_color = vec3(1.0, 0.84, 0.2);   // 金
    }

    // 符文用略亮色
    vec3 rune_color = base_color * 1.3 + vec3(0.1);

    // --- 合成 ---
    float alpha = (ring * pulse * 0.5 + fill * pulse2 + rune_pattern * 0.6) * glow_intensity;
    vec3 final_color = mix(base_color, rune_color, rune_pattern);

    COLOR = vec4(final_color, alpha * COLOR.a);
}
