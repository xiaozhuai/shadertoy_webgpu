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

@fragment
fn fs_main(input: FragmentInput) -> FragmentOutput {
    var uv = (2.0 * input.fragCoord - iResolution) / iResolution.y;
    var uv2 = uv;
    uv2.x += iResolution.x / iResolution.y;
    uv2.x -= 2.0 * (iTime % (1.0 * iResolution.x / iResolution.y));
    let width = -(1.0 / (25.0 * uv2.x));
    let l = vec3f(width , width * 1.9, width * 1.5);
    uv.y *= 2.0;
    let xx = abs(1.0 / (20.0 * max(abs(uv.x), 0.3)));
    uv.x *= 3.0;
    uv.y -= xx * (sin(uv.x) + 3.0 * sin(2.0 * uv.x) + 2.0 * sin(3.0 * uv.x) + sin(4.0 * uv.x));
    let col = mix(vec3f(1), vec3f(0), smoothstep(0.02, 0.03, abs(uv.y)));
    var output: FragmentOutput;
    output.color = vec4f(col * l, 1.0);
    return output;
}
