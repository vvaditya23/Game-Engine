//
//  GameView.swift
//  Game Engine
//
//  Created by Aditya Vyavahare on 26/12/24.
//

import MetalKit

class GameView: MTKView {
    var commandQueue: MTLCommandQueue!

    /// Render pipeline state contains render pipeline descriptor
    /// - Render pipeline descriptor contains ->
    ///     1. Color attachments (pixel format)
    ///     2. Vertex function (made by MTL library in .metal file)
    ///     3. Fragment function (made by MTL library in .metal file)
    var renderPipelineState: MTLRenderPipelineState!

    let vertices: [float3] = [
        float3(0, 1, 0),    // top middle
        float3(-1, -1, 0),  // bottom left
        float3(1, -1, 0)    // bottom right
    ]
    var vertexBuffer: MTLBuffer!

    required init(coder: NSCoder) {
        super.init(coder: coder)
        /// Abstract representation of GPU
        /// Create metal GPU objects and send it down to the GPU
        self.device = MTLCreateSystemDefaultDevice()

        /// Color that clears the drawing while new frame is rendered (eg. 60FPS, 60 frames are rendered back-to-back)
        self.clearColor = MTLClearColor(red: 0.43, green: 0.73, blue: 0.35, alpha: 1)

        /// Used to match the O/P of fragment shader (NSView's pixel format)
        self.colorPixelFormat = .bgra8Unorm

        /// Acts as limiter to push buffers to (clear) screen, populated with command buffers
        /// commandQueue follows FIFO approach
        commandQueue = device?.makeCommandQueue()

        createRenderPipelineState()
        createVertexBuffers()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let drawable = self.currentDrawable, let renderPassDescriptor = self.currentRenderPassDescriptor else { return }

        /// Objects that are pushed into command queue
        let commandBuffer = commandQueue?.makeCommandBuffer()

        /// Tells command buffer what to do when it is committed
        /// Four types ->
        /// 1. Render command encode: Render graphics (does not do any computations on buffer except what's on basic vertex & fragment shader)
        /// 2. Computer command encoder: Computational tasks & mathematics, things that are to be multi-thread over GPU (no graphics)
        /// 3. Blit command encoder: Memory management tasks
        /// 4. Parallel command encoder: Multiple graphics rendering tasks (asynchronously)
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderCommandEncoder?.setRenderPipelineState(renderPipelineState)

        // Send info to renderCommandEncoder
        renderCommandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)

        renderCommandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

    private func createRenderPipelineState() {
        let library = device?.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "basic_vertex_shader")
        let fragmentFunction = library?.makeFunction(name: "basic_fragment_shader")

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction

        do {
            renderPipelineState = try device?.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch let error as NSError {
            print("Failed to create render pipeline state: \(error)")
        }
    }

    private func createVertexBuffers() {
        /// length: It is amount of memory that needs to be buffered out
        ///     float3 is 16bytes, vertices.count is 3 = 16 times 3 is the memory buffered out here
        vertexBuffer = device?.makeBuffer(bytes: vertices, length: MemoryLayout<float3>.stride * vertices.count, options: [])
    }
}
