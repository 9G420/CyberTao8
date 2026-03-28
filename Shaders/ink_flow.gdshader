// ============================================================
// ink_flow.gdshader - 道教墨迹流动效果
// 用于回合开始墨迹扩散、召唤时符文雨
// 支持触发模式（一次性扩散）和持续模式（微弱流动底纹）
// GL Compatibility 兼容
// ============================================================
shader_type canvas_item;

// 墨迹颜色：0=黑墨, 1=紫墨(阴), 2=金墨(阳)
uniform int ink_color_mode : hint_range(0, 2) = 0;
uniform float ink_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float flow_speed : hint_range(0.1, 3.0) = 0.4;
// 扩散中心 (0.5, 0.5 = 屏幕中心)
uniform vec2 origin = vec2(0.5, 0.5);
// 扩散半径（0=无扩散，1=全屏）
uniform float spread_radius : hint_range(0.0, 1.5) = 0.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 st) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * value_noise(st);
        st *= 2.1;
        a *= 0.45;
    }
    return v;
}

void fragment() {
    vec2 uv = UV;
    vec2 to_center = uv - origin;
    float dist_from_origin = length(to_center);

    // --- 墨迹噪声纹理（模拟毛笔墨水扩散）---
    vec2 ink_uv = uv * 5.0 + vec2(TIME * flow_speed * 0.3, TIME * flow_speed * 0.2);
    float ink1 = fbm(ink_uv);
    float ink2 = fbm(ink_uv * 1.3 + vec2(5.3, 2.7) + TIME * flow_speed * 0.15);

    // 墨滴聚散效果（深浅交替的墨纹）
    float ink_pattern = smoothstep(0.35, 0.6, ink1) * 0.6;
    float ink_vein = smoothstep(0.4, 0.55, ink2) * 0.4;
    float ink = ink_pattern + ink_vein;

    // --- 扩散遮罩（从 origin 向外扩散）---
    float spread_mask = 1.0;
    if (spread_radius > 0.01) {
        // 带噪声边缘的扩散圆
        float noise_edge = fbm(uv * 8.0 + TIME * 0.5) * 0.1;
        spread_mask = smoothstep(spread_radius, spread_radius - 0.15, dist_from_origin + noise_edge);
    }

    // --- 颜色 ---
    vec3 ink_color;
    if (ink_color_mode == 0) {
        ink_color = vec3(0.02, 0.01, 0.04); // 黑墨
    } else if (ink_color_mode == 1) {
        vec3 dark = vec3(0.12, 0.02, 0.22);
        vec3 light = vec3(0.3, 0.08, 0.5);
        ink_color = mix(dark, light, ink1 * 0.5);
    } else {
        vec3 dark = vec3(0.2, 0.15, 0.02);
        vec3 light = vec3(0.5, 0.4, 0.1);
        ink_color = mix(dark, light, ink1 * 0.5);
    }

    float final_alpha = ink * spread_mask * ink_intensity;
    COLOR = vec4(ink_color, final_alpha * COLOR.a);
}
