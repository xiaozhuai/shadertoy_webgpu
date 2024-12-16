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

fn palette(t: f32) -> vec3f {
    let a = vec3f(0.5, 0.5, 0.5);
    let b = vec3f(0.5, 0.5, 0.5);
    let c = vec3f(1.0, 1.0, 1.0);
    let d = vec3f(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

@fragment
fn fs_main(input: FragmentInput) -> FragmentOutput {
    var uv = (2.0 * input.fragCoord - iResolution) / iResolution.y;
    var uv0 = uv;
    var finalColor = vec3f(0.0);
    for (var i = 0.0; i < 4.0; i += 1.0) {
        uv = fract(uv * 1.5) - 0.5;
        var d = length(uv) * exp(-length(uv0));
        let col = palette(length(uv0) + i * 0.4 + iTime * 0.4);
        d = sin(d * 8.0 + iTime)/8.;
        d = abs(d);
        d = pow(0.01 / d, 1.2);
        finalColor += col * d;
    }
    var output: FragmentOutput;
    output.color = vec4f(finalColor, 1.0);
    return output;
}
