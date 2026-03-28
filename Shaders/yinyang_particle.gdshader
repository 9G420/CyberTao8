// ============================================================
// yinyang_particle.gdshader - 增强阴阳粒子特效 (Enhanced YinYang Particle)
// 四模式：阴/阳/共鸣/反噬 (4 modes: Yin/Yang/Resonance/Backlash)
// 太极旋转 + 拖尾 + 龟裂纹 (Taiji rotation + trails + crack patterns)
// GL Compatibility兼容版 - canvas_item覆盖层
// ============================================================
shader_type canvas_item;

// === 颜色模式 (Color Mode) ===
// 0=阴(紫墨), 1=阳(金火), 2=共鸣(彩虹), 3=反噬(血裂)
// 0=Yin(purple ink), 1=Yang(golden fire), 2=Resonance(rainbow), 3=Backlash(blood crack)
uniform int color_mode : hint_range(0, 3) = 0;

// === 发光参数 (Glow Parameters) ===
uniform float glow_intensity : hint_range(0.0, 4.0) = 1.8;
// 脉冲发光速度 (Pulse glow speed, used in resonance mode)
uniform float pulse_speed : hint_range(0.0, 10.0) = 3.0;

// === 太极旋转 (Taiji Rotation) ===
uniform float rotation_speed : hint_range(0.0, 12.0) = 2.5;
// 太极图案强度 (Taiji pattern strength)
uniform float taiji_strength : hint_range(0.0, 1.0) = 0.6;

// === 拖尾效果 (Trail Effect) ===
// 拖尾长度 (Trail length factor)
uniform float trail_length : hint_range(0.0, 1.0) = 0.5;
// 拖尾方向角度 (Trail direction angle in radians)
uniform float trail_angle : hint_range(0.0, 6.283) = 0.0;

// === 反噬模式参数 (Backlash Mode Parameters) ===
// 龟裂密度 (Crack pattern density)
uniform float crack_density : hint_range(2.0, 20.0) = 8.0;
// 龟裂锐度 (Crack sharpness)
uniform float crack_sharpness : hint_range(1.0, 20.0) = 8.0;

// ─── 工具函数 (Utility Functions) ───

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}

// 值噪声 (Value noise for organic textures)
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

// 分形噪声 (Fractal Brownian Motion for ink/fire textures)
float fbm(vec2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    vec2 shift = vec2(100.0);
    for (int i = 0; i < 4; i++) {
        value += amplitude * value_noise(st);
        st = st * 2.0 + shift;
        amplitude *= 0.5;
    }
    return value;
}

// Voronoi距离场，用于龟裂纹 (Voronoi distance field for crack patterns)
float voronoi_cracks(vec2 st, float density) {
    vec2 i_st = floor(st * density);
    vec2 f_st = fract(st * density);

    float min_dist = 1.0;
    float second_dist = 1.0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            vec2 point = vec2(hash(i_st + neighbor), hash(i_st + neighbor + vec2(37.0, 91.0)));
            // 让裂纹微微蠕动 (Slight animation of crack pattern)
            point = 0.5 + 0.5 * sin(TIME * 0.8 + 6.2831 * point);
            vec2 diff = neighbor + point - f_st;
            float dist = length(diff);
            if (dist < min_dist) {
                second_dist = min_dist;
                min_dist = dist;
            } else if (dist < second_dist) {
                second_dist = dist;
            }
        }
    }
    // 返回边缘距离（越小越接近裂缝）(Return edge distance - smaller = closer to crack)
    return second_dist - min_dist;
}

void fragment() {
    vec2 center = UV - vec2(0.5);
    float dist = length(center);
    float angle = atan(center.y, center.x);

    // 太极旋转角 (Taiji rotation angle)
    float rot_angle = angle + TIME * rotation_speed;

    // ─── 圆形基础遮罩 (Circular Base Mask) ───
    float mask = smoothstep(0.5, 0.38, dist);

    // ─── 拖尾效果 (Trail Effect) ───
    // 在拖尾方向上拉伸遮罩 (Stretch mask in trail direction)
    if (trail_length > 0.01) {
        vec2 trail_dir = vec2(cos(trail_angle), sin(trail_angle));
        float trail_proj = dot(center, trail_dir);
        // 只在运动反方向产生拖尾 (Trail only behind movement direction)
        float trail_mask = smoothstep(0.0, -trail_length * 0.8, trail_proj);
        // 拖尾区域的横向收窄 (Narrow the trail laterally)
        vec2 perp_dir = vec2(-trail_dir.y, trail_dir.x);
        float perp_dist = abs(dot(center, perp_dir));
        float trail_width = smoothstep(0.2, 0.05, perp_dist);
        float trail_fade = trail_mask * trail_width * (1.0 - smoothstep(0.0, trail_length, -trail_proj));
        mask = max(mask, trail_fade * 0.6);
    }

    // ─── 太极图案 (Taiji / Yin-Yang Pattern) ───
    // S曲线分割阴阳 (S-curve divides yin and yang)
    float taiji_s = sin(rot_angle);
    float taiji_half = step(0.0, center.x * cos(TIME * rotation_speed)
                                + center.y * sin(TIME * rotation_speed));
    // 两个小圆点 (Two small dots)
    vec2 rot_center1 = vec2(cos(TIME * rotation_speed), sin(TIME * rotation_speed)) * 0.15;
    vec2 rot_center2 = -rot_center1;
    float dot1 = smoothstep(0.08, 0.05, length(center - rot_center1));
    float dot2 = smoothstep(0.08, 0.05, length(center - rot_center2));
    // 太极混合值: 0=阴半, 1=阳半 (Taiji blend: 0=yin half, 1=yang half)
    float taiji_blend = mix(taiji_half, 1.0 - taiji_half, dot1);
    taiji_blend = mix(taiji_blend, taiji_half, dot2);

    // ─── 根据模式计算颜色 (Calculate Color per Mode) ───
    vec3 base_color = vec3(0.0);
    float mode_alpha = 1.0;

    if (color_mode == 0) {
        // ─── 阴模式: 深紫+流动墨迹 (Yin Mode: Deep Purple + Flowing Ink) ───
        // 墨迹流动噪声 (Flowing ink noise texture)
        vec2 ink_uv = center * 3.0 + vec2(TIME * 0.2, TIME * 0.15);
        float ink = fbm(ink_uv);
        float ink2 = fbm(ink_uv * 1.5 + vec2(5.0, 3.0) + TIME * 0.1);

        // 深紫基底 (Deep purple base)
        vec3 purple_deep = vec3(0.18, 0.03, 0.45);
        vec3 purple_light = vec3(0.4, 0.1, 0.75);
        // 墨迹纹理调制 (Ink texture modulation)
        base_color = mix(purple_deep, purple_light, ink * 0.7);
        // 流动的暗色墨纹 (Flowing dark ink veins)
        float vein = smoothstep(0.3, 0.5, ink2);
        base_color = mix(base_color, purple_deep * 0.5, vein * 0.4);
        // 太极图案融入 (Blend taiji pattern)
        base_color = mix(base_color, base_color * 0.4, taiji_blend * taiji_strength);

    } else if (color_mode == 1) {
        // ─── 阳模式: 金色+火焰边缘 (Yang Mode: Golden + Fire-like Edges) ───
        vec3 gold_core = vec3(1.0, 0.85, 0.25);
        vec3 fire_orange = vec3(1.0, 0.45, 0.05);
        vec3 fire_red = vec3(0.95, 0.15, 0.0);

        // 火焰噪声 (Fire noise - upward flowing)
        vec2 fire_uv = center * 4.0 + vec2(0.0, -TIME * 0.8);
        float fire = fbm(fire_uv);
        float fire2 = fbm(fire_uv * 2.0 + TIME * 0.5);

        // 中心金色，边缘渐变到火焰色 (Gold center, fire edges)
        float edge_factor = smoothstep(0.15, 0.45, dist);
        base_color = mix(gold_core, fire_orange, edge_factor);
        // 火焰扰动 (Fire disturbance)
        base_color = mix(base_color, fire_red, fire * edge_factor * 0.6);
        // 火焰尖端的亮白 (Bright tips of flames)
        float tip = fire2 * edge_factor * smoothstep(0.3, 0.48, dist);
        base_color = mix(base_color, vec3(1.0, 0.95, 0.7), tip * 0.4);
        // 太极反向（阳半更亮）(Taiji inverse - yang half brighter)
        base_color *= 1.0 + (1.0 - taiji_blend) * taiji_strength * 0.4;

    } else if (color_mode == 2) {
        // ─── 共鸣模式: 彩虹+脉冲发光 (Resonance Mode: Rainbow + Pulsing Glow) ───
        // 旋转彩虹 (Rotating rainbow)
        float hue = fract(rot_angle / 6.2831 + TIME * 0.3);
        // HSV to RGB (简化版)
        float h6 = hue * 6.0;
        float r = abs(h6 - 3.0) - 1.0;
        float g = 2.0 - abs(h6 - 2.0);
        float b = 2.0 - abs(h6 - 4.0);
        base_color = clamp(vec3(r, g, b), 0.0, 1.0);

        // 径向彩虹层叠 (Radial rainbow layering)
        float radial_hue = fract(dist * 3.0 - TIME * 0.5);
        float rh6 = radial_hue * 6.0;
        vec3 radial_col = clamp(vec3(
            abs(rh6 - 3.0) - 1.0,
            2.0 - abs(rh6 - 2.0),
            2.0 - abs(rh6 - 4.0)
        ), 0.0, 1.0);
        base_color = mix(base_color, radial_col, 0.3);

        // 脉冲发光 (Pulsing glow)
        float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7;
        base_color *= pulse;
        // 饱和度增强 (Saturation boost)
        base_color = mix(vec3(dot(base_color, vec3(0.299, 0.587, 0.114))), base_color, 1.4);
        base_color = clamp(base_color, 0.0, 1.0);

    } else {
        // ─── 反噬模式 (color_mode 3): 血红+龟裂纹 ───
        // (Backlash Mode: Blood Red + Cracking Pattern)
        vec3 blood_dark = vec3(0.35, 0.02, 0.02);
        vec3 blood_bright = vec3(0.95, 0.1, 0.05);
        vec3 crack_glow = vec3(1.0, 0.3, 0.1); // 裂缝发光色 (Crack glow color)

        // 血色基底，带脉动 (Blood base with pulsation)
        float blood_pulse = sin(TIME * 4.0) * 0.15 + 0.85;
        base_color = mix(blood_dark, blood_bright, 0.4 * blood_pulse);

        // 龟裂纹路 (Crack pattern via Voronoi)
        float crack_raw = voronoi_cracks(UV, crack_density);
        // 锐化裂缝线 (Sharpen crack lines)
        float crack_line = 1.0 - smoothstep(0.0, 0.12 / crack_sharpness, crack_raw);

        // 裂缝发光 (Glowing cracks)
        base_color = mix(base_color, crack_glow, crack_line * 0.8);
        // 裂缝处更亮 (Brighter at crack lines)
        base_color += crack_line * vec3(0.3, 0.05, 0.0);

        // 暗色脉络 (Dark veins between cracks)
        float vein_noise = fbm(center * 6.0 + TIME * 0.3);
        base_color = mix(base_color, blood_dark * 0.5, vein_noise * 0.3);

        // 边缘碎裂加剧 (Intensified cracking at edges)
        float edge_crack = smoothstep(0.2, 0.45, dist);
        base_color = mix(base_color, crack_glow * 0.6, edge_crack * crack_line * 0.5);

        // 整体脉动 (Overall throbbing)
        mode_alpha = 0.85 + sin(TIME * 6.0) * 0.1;
    }

    // ─── 发光效果 (Glow Effect) ───
    // 中心点发光 (Center point glow)
    float glow = exp(-dist * 5.0) * glow_intensity;
    // 发光色与基色同调 (Glow color matches base tone)
    vec3 glow_color = base_color * 1.5 + vec3(0.1);
    vec3 final_color = base_color + glow_color * glow;

    // 柔和亮度钳制 (Soft brightness clamp)
    final_color = clamp(final_color, 0.0, 1.5);

    // ─── 最终输出 (Final Output) ───
    float final_alpha = mask * mode_alpha * COLOR.a;
    COLOR = vec4(final_color, final_alpha);
}
