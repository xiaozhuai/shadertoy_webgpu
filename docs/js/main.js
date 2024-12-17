const canvas = document.querySelector('#canvas');
if (!navigator.gpu) {
    throw new Error("WebGPU not supported on this browser.");
}

const adapter = await navigator.gpu.requestAdapter();
if (!adapter) {
    throw new Error("No appropriate adapter found.");
}
// console.log(`Adapter features:`);
// for (const feature of adapter.features) {
//     console.log(`  - ${feature}`);
// }
// console.log(`Adapter info:`);
// for (let key in adapter.info) {
//     console.log(`  - ${key}: ${adapter.info[key]}`);
// }

const device = await adapter.requestDevice();
if (!device) {
    throw new Error("No appropriate device found.");
}
// console.log(`Device features:`);
// for (const feature of device.features) {
//     console.log(`  - ${feature}`);
// }
// console.log(`Device limits:`);
// for (let key in device.limits) {
//     console.log(`  - ${key}: ${device.limits[key]}`);
// }

const context = canvas.getContext("webgpu");
const canvasFormat = navigator.gpu.getPreferredCanvasFormat();
context.configure({
    device: device,
    format: canvasFormat,
});

const vertices = new Float32Array([
    -1.0, -1.0,
    1.0, -1.0,
    1.0, 1.0,
    -1.0, -1.0,
    1.0, 1.0,
    -1.0, 1.0,
]);
const vertexBuffer = device.createBuffer({
    label: 'vertex buffer',
    size: vertices.byteLength,
    usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
});
device.queue.writeBuffer(vertexBuffer, 0, vertices);
const vertexBufferLayout = {
    arrayStride: 4 * 2,
    attributes: [{
        format: 'float32x2',
        offset: 0,
        shaderLocation: 0,
    }],
};

const resolutionUniformBuffer = device.createBuffer({
    label: 'resolution uniform buffer',
    size: 4 * 2,
    usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
});
const updateResolution = (width, height) => {
    const data = new Float32Array([width, height]);
    device.queue.writeBuffer(resolutionUniformBuffer, 0, data);
};

const timeUniformBuffer = device.createBuffer({
    label: 'time uniform buffer',
    size: 4,
    usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
});
const updateTime = (time) => {
    const data = new Float32Array([time]);
    device.queue.writeBuffer(timeUniformBuffer, 0, data);
}

const getShaderCode = async (url) => {
    const res = await fetch(url);
    return await res.text();
}

const createPipeline = async (shaderUrl) => {
    const shaderCode = await getShaderCode(shaderUrl);
    const shaderModule = device.createShaderModule({
        label: 'shader module',
        code: shaderCode,
    });
    return await device.createRenderPipelineAsync({
        label: 'render pipeline',
        layout: 'auto',
        vertex: {
            module: shaderModule,
            entryPoint: 'vs_main',
            buffers: [vertexBufferLayout],
        },
        fragment: {
            module: shaderModule,
            entryPoint: 'fs_main',
            targets: [{
                format: canvasFormat,
            }],
        },
    });
}

const createBindGroup = (pipeline) => {
    return device.createBindGroup({
        label: 'bind group',
        layout: pipeline.getBindGroupLayout(0),
        entries: [{
            binding: 0,
            resource: {buffer: resolutionUniformBuffer},
        }, {
            binding: 1,
            resource: {buffer: timeUniformBuffer},
        }],
    });
}

let pipeline = null;
let bindGroup = null;

const initToy = async (toyName) => {
    const shaderUrl = `shader/${toyName}.wgsl`;
    console.log(`Load shader: ${shaderUrl}`);
    pipeline = await createPipeline(shaderUrl);
    bindGroup = createBindGroup(pipeline);
};

const shaderSelect = document.querySelector('#shader-select');
await initToy(shaderSelect.value);
shaderSelect.addEventListener('change', async () => {
    await initToy(shaderSelect.value);
});

const openInShadertoyButton = document.querySelector('#open-in-shadertoy');
openInShadertoyButton.addEventListener('click', () => {
    window.open(`https://www.shadertoy.com/view/${shaderSelect.value}`);
});

const switchFullscreen = async () => {
    if (document.fullscreenElement) {
        await document.exitFullscreen();
    } else {
        await canvas.requestFullscreen();
    }
};
canvas.addEventListener('dblclick', async () => {
    await switchFullscreen();
});
const fullscreenButton = document.querySelector('#fullscreen');
fullscreenButton.addEventListener('click', async () => {
    await switchFullscreen();
});

class FpsCounter {
    constructor(callback) {
        this.fpsUpdateCallback = callback;
        this.startTime = 0;
        this.frameCount = 0;
    }

    update() {
        const currentTime = performance.now();
        if (this.startTime === 0) {
            this.startTime = currentTime;
        } else if (currentTime - this.startTime >= 1000) {
            this.fps = this.frameCount * 1000 / (currentTime - this.startTime);
            this.fpsUpdateCallback(this.fps);
            this.startTime = currentTime;
            this.frameCount = 0;
        } else {
            this.frameCount++;
        }
    }
}

const fpsText = document.querySelector('#fps');
const fpsCounter = new FpsCounter((fps) => {
    fpsText.textContent = `${fps.toFixed(2)} fps`;
});

class Timeline {
    constructor() {
        this.startTime = performance.now() / 1000;
        this.isPaused = false;
    }

    get() {
        if (this.isPaused) {
            return this.pauseTime - this.startTime;
        } else {
            return performance.now() / 1000 - this.startTime;
        }
    }

    pause() {
        this.isPaused = true;
        this.pauseTime = performance.now() / 1000;
    }

    resume() {
        this.isPaused = false;
        this.startTime += performance.now() / 1000 - this.pauseTime;
    }
}

const timeText = document.querySelector('#time');
const timeline = new Timeline();

const pauseButton = document.querySelector('#pause');
pauseButton.addEventListener('click', () => {
    if (!timeline.isPaused) {
        timeline.pause();
        pauseButton.classList.remove('icon-pause');
        pauseButton.classList.add('icon-play');
    } else {
        timeline.resume();
        pauseButton.classList.remove('icon-play');
        pauseButton.classList.add('icon-pause');
    }
});

function render() {
    const time = timeline.get();
    timeText.textContent = `${time.toFixed(2)}`;

    updateResolution(canvas.width, canvas.height);
    updateTime(time);

    const encoder = device.createCommandEncoder();
    const pass = encoder.beginRenderPass({
        colorAttachments: [{
            view: context.getCurrentTexture().createView(),
            clearValue: [0.0, 0.0, 0.0, 1.0],
            loadOp: 'clear',
            storeOp: 'store',
        }],
    });
    pass.setPipeline(pipeline);
    pass.setVertexBuffer(0, vertexBuffer);
    pass.setBindGroup(0, bindGroup);
    pass.draw(vertices.length / 2);
    pass.end();
    const commandBuffer = encoder.finish();
    device.queue.submit([commandBuffer]);

    fpsCounter.update();
    requestAnimationFrame(render);
}

requestAnimationFrame(render);
