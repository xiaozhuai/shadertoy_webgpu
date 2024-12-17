@group(0) @binding(0) var<uniform> iResolution: vec2f;
@group(0) @binding(1) var<uniform> iTime: f32;

struct VertexInput {
    @location(0) pos: vec2f,
};

struct VertexOutput {
    @builtin(position) pos: vec4f,
    @location(0) fragCoord: vec2f,
};

@vertex
fn vs_main(input: VertexInput) -> VertexOutput {
    var output: VertexOutput;
    output.pos = vec4f(input.pos, 0.0, 1.0);
    output.fragCoord = (input.pos * 0.5 + 0.5) * iResolution;
    return output;
}

struct FragmentInput {
    @location(0) fragCoord: vec2f,
};

struct FragmentOutput {
    @location(0) color: vec4f,
};

const PI: f32 = 3.14159265359;
const PI2: f32 = 6.28318530718;

fn rot(a: f32) -> mat2x2<f32> {
    return mat2x2<f32>(
        vec2<f32>(cos(a), sin(a)),
        vec2<f32>(-sin(a), cos(a))
    );
}

fn hue(t: f32, f: f32) -> vec3<f32> {
    return f + f * cos(PI2 * t * (vec3<f32>(1.0, 0.75, 0.75) + vec3<f32>(0.96, 0.57, 0.12)));
}

fn hash21(a: vec2<f32>) -> f32 {
    return fract(sin(dot(a, vec2<f32>(27.69, 32.58))) * 43758.53);
}

fn box(p: vec2<f32>, b: vec2<f32>) -> f32 {
    let d = abs(p) - b;
    return length(max(d, vec2<f32>(0.0))) + min(max(d.x, d.y), 0.0);
}

var<private> r90: mat2x2<f32>;

fn pattern(p: vec2<f32>, sc: f32) -> vec2<f32> {
    var uv = p;
    let id = floor(p * sc);
    var p_mod = fract(p * sc) - 0.5;

    var rnd = hash21(id);

    // turn tiles
    if (rnd > 0.5) {
        p_mod = r90 * p_mod;
    }
    rnd = fract(rnd * 32.54);
    if (rnd > 0.4) {
        p_mod = r90 * p_mod;
    }
    if (rnd > 0.8) {
        p_mod = r90 * p_mod;
    }

    // randomize hash for type
    rnd = fract(rnd * 47.13);

    let tk = 0.075;
    // kind of messy and long winded
    var d = box(p_mod - vec2<f32>(0.6, 0.7), vec2<f32>(0.25, 0.75)) - 0.15;
    var l = box(p_mod - vec2<f32>(0.7, 0.5), vec2<f32>(0.75, 0.15)) - 0.15;
    var b = box(p_mod + vec2<f32>(0.0, 0.7), vec2<f32>(0.05, 0.25)) - 0.15;
    var r = box(p_mod + vec2<f32>(0.6, 0.0), vec2<f32>(0.15, 0.05)) - 0.15;
    d = abs(d) - tk;

    if (rnd > 0.92) {
        d = box(p_mod - vec2<f32>(-0.6, 0.5), vec2<f32>(0.25, 0.15)) - 0.15;
        l = box(p_mod - vec2<f32>(0.6, 0.6), vec2<f32>(0.25)) - 0.15;
        b = box(p_mod + vec2<f32>(0.6, 0.6), vec2<f32>(0.25)) - 0.15;
        r = box(p_mod - vec2<f32>(0.6, -0.6), vec2<f32>(0.25)) - 0.15;
        d = abs(d) - tk;
    } else if (rnd > 0.6) {
        d = length(p_mod.x - 0.2) - tk;
        l = box(p_mod - vec2<f32>(-0.6, 0.5), vec2<f32>(0.25, 0.15)) - 0.15;
        b = box(p_mod + vec2<f32>(0.6, 0.6), vec2<f32>(0.25)) - 0.15;
        r = box(p_mod - vec2<f32>(0.3, 0.0), vec2<f32>(0.25, 0.05)) - 0.15;
    }

    l = abs(l) - tk;
    b = abs(b) - tk;
    r = abs(r) - tk;

    let e = min(d, min(l, min(b, r)));

    if (rnd > 0.6) {
        r = max(r, -box(p_mod - vec2<f32>(0.2, 0.2), vec2<f32>(tk * 1.3)));
        d = max(d, -box(p_mod + vec2<f32>(-0.2, 0.2), vec2<f32>(tk * 1.3)));
    } else {
        l = max(l, -box(p_mod - vec2<f32>(0.2, 0.2), vec2<f32>(tk * 1.3)));
    }

    d = min(d, min(l, min(b, r)));

    return vec2<f32>(d, e);
}

@fragment
fn fs_main(input: FragmentInput) -> FragmentOutput {
    var uv = (2.0 * input.fragCoord - iResolution) / max(iResolution.x, iResolution.y);
    r90 = rot(1.5707);

    uv = rot(iTime * 0.095) * uv;
    uv = vec2<f32>(log(length(uv)), atan2(uv.y, uv.x) * 6.0 / PI2);

    var C = vec3<f32>(0.0);
    var scale = 8.0;
    for(var i: f32 = 0.0; i < 4.0; i += 1.0) {
        let ff = (i * 0.05) + 0.2;
        uv.x += iTime * ff;

        let px = fwidth(uv.x * scale);
        let d = pattern(uv, scale);
        let clr = hue(sin(uv.x + (i * 8.0)) * 0.2 + 0.4, (0.5 + i) * 0.15);
        C = mix(C, vec3<f32>(0.001), smoothstep(px, -px, d.y - 0.04));
        C = mix(C, clr, smoothstep(px, -px, d.x));
        scale *= 0.5;
    }

    C = pow(C, vec3<f32>(0.4545));
    var output: FragmentOutput;
    output.color = vec4f(C, 1.0);
    return output;
}
