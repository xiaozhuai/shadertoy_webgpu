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
    var uv = (2.0 * input.fragCoord - iResolution) / min(iResolution.x, iResolution.y);
    for(var i = 1.0; i < 10.0; i += 1.0) {
        uv.x += 0.6 / i * cos(i * 2.5 * uv.y + iTime);
        uv.y += 0.6 / i * cos(i * 1.5 * uv.x + iTime);
    }
    let color = vec3f(0.1) / abs(sin(iTime - uv.y - uv.x));
    var output: FragmentOutput;
    output.color = vec4f(color, 1.0);
    return output;
}
