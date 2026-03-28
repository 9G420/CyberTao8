// ============================================================
// energy_field.gdshader - 战场能量场背景层
// 流动电路符文 + 太极八卦暗纹 + 雾气
// 覆盖在战斗背景之上，play_zone之下
// GL Compatibility 兼容
// ============================================================
shader_type canvas_item;

uniform float field_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float circuit_speed : hint_range(0.1, 3.0) = 0.5;
uniform float fog_density : hint_range(0.0, 1.0) = 0.25;
// 0=normal, 1=resonance(彩虹加强), 2=backlash(红色裂纹)
uniform int battle_state : hint_range(0, 2) = 0;

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
    for (int i = 0; i < 3; i++) {
        v += a * value_noise(st);
        st *= 2.0;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV;
    vec2 center = uv - vec2(0.5);

    // --- 电路网格纹路（正交线条 + 节点亮点）---
    vec2 grid_uv = uv * 12.0 + vec2(TIME * circuit_speed * 0.3, TIME * circuit_speed * 0.15);
    vec2 grid_fract = fract(grid_uv);
    float h_line = smoothstep(0.02, 0.0, abs(grid_fract.y - 0.5));
    float v_line = smoothstep(0.02, 0.0, abs(grid_fract.x - 0.5));
    float circuit = max(h_line, v_line) * 0.4;
    // 网格节点亮点
    float node_glow = smoothstep(0.08, 0.0, length(grid_fract - vec2(0.5)));
    circuit += node_glow * 0.6;
    // 让电路网格随时间部分闪烁
    float flicker = step(0.7, hash(floor(grid_uv) + floor(TIME * 2.0)));
    circuit *= (0.4 + flicker * 0.6);

    // --- 太极暗纹（大型旋转，低透明度）---
    float taiji_dist = length(center);
    float taiji_angle = atan(center.y, center.x) + TIME * 0.15;
    float taiji_s = sin(taiji_angle * 1.0) * 0.5 + 0.5;
    float taiji_mask = smoothstep(0.45, 0.25, taiji_dist);
    float taiji = taiji_s * taiji_mask * 0.15;

    // --- 雾气层（缓慢流动的 fbm 噪声）---
    vec2 fog_uv = uv * 3.0 + vec2(TIME * 0.08, TIME * 0.05);
    float fog = fbm(fog_uv) * fog_density;

    // --- 颜色 ---
    vec3 circuit_color = vec3(0.0, 0.56, 0.63); // 暗青
    vec3 taiji_color = vec3(0.18, 0.08, 0.32);  // 暗紫
    vec3 fog_color = vec3(0.06, 0.03, 0.12);    // 深墨

    if (battle_state == 1) {
        // 共鸣：电路变金色，太极变亮
        circuit_color = vec3(0.8, 0.65, 0.15);
        taiji_color = vec3(0.3, 0.2, 0.5);
        float pulse = sin(TIME * 3.0) * 0.15 + 0.85;
        circuit *= pulse;
    } else if (battle_state == 2) {
        // 反噬：电路变红，雾气加重
        circuit_color = vec3(0.7, 0.05, 0.05);
        fog_color = vec3(0.15, 0.02, 0.02);
        fog *= 1.5;
    }

    vec3 final_color = circuit_color * circuit + taiji_color * taiji + fog_color * fog;
    float final_alpha = (circuit * 0.7 + taiji * 0.5 + fog * 0.8) * field_intensity;

    COLOR = vec4(final_color, final_alpha * COLOR.a);
}
