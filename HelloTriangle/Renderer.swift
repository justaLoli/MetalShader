//
//  Renderer.swift
//  HelloTriangle
//
//  Created by Just aLoli on 2024/6/28.
//

import MetalKit

class Renderer: NSObject, MTKViewDelegate{
    var parent: ContentView;
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    let vertexBuffer: MTLBuffer;
    let indexBuffer: MTLBuffer;
    let pipelineState: MTLRenderPipelineState;
    
    //尝试给渲染器传入外部参数，比如运行时间
    var uniformsBuffer: MTLBuffer!
    var frameNumber: Float = 0
    var startTime: TimeInterval = 0
    var iResolution = vector_float2(0,0);
    
    
    init(_ parent: ContentView){
        
        self.parent = parent;
        if let metalDevice = MTLCreateSystemDefaultDevice(){
            self.metalDevice = metalDevice;
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue();
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor();
        let library = metalDevice.makeDefaultLibrary() // load Shaders.metal file, so the filename matters.
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do{
            try pipelineState = metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch{
            fatalError("pipelineState creation failed");
        }
        
        
        let vertices = [
            Vertex(position: [-1, -1], color: [1, 0, 0, 1]),  // A
            Vertex(position: [1, -1], color: [0, 1, 0, 1]),   // B
            Vertex(position: [1, 1], color: [0, 0, 1, 1]),    // C
            Vertex(position: [-1, 1], color: [1, 1, 0, 1])    // D
        ]
        
        let indices: [UInt16] = [
            0, 1, 2,  // 第一个三角形：左下角 -> 右下角 -> 右上角
            0, 2, 3   // 第二个三角形：左下角 -> 右上角 -> 左上角
        ]
        
        
        vertexBuffer = metalDevice.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])!
        indexBuffer = metalDevice.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.stride, options: [])!
        
        //init the uniform buffer
        uniformsBuffer = metalDevice.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: [])!
        // 记录开始时间
        frameNumber = 0;
        startTime = CACurrentMediaTime()
        
        super.init()
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.iResolution = vector_float2(Float(size.width), Float(size.height))
    }
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }

        //update the uniform variable.
        self.frameNumber += 1
        let elapsedTime = Float(CACurrentMediaTime() - startTime)
        
        
        // 将Uniform数据写入缓冲区
        var uniforms = Uniforms(frameNumber: frameNumber, elapsedTime: elapsedTime, iResolution: self.iResolution)
        memcpy(uniformsBuffer.contents(), &uniforms, MemoryLayout<Uniforms>.stride)
        
        
        let commandBuffer = metalCommandQueue.makeCommandBuffer ()

        let renderPassDescriptor = view.currentRenderPassDescriptor
        renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0.5, 0.5, 1.0)
        renderPassDescriptor?.colorAttachments[0].loadAction = .clear
        renderPassDescriptor?.colorAttachments[0].storeAction = .store

        let renderEncoder = commandBuffer?.makeRenderCommandEncoder (descriptor: renderPassDescriptor!)

        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setFragmentBuffer(uniformsBuffer, offset: 0, index: 1)
//        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: 6, indexType: .uint16, indexBuffer: self.indexBuffer, indexBufferOffset: 0);
        
        renderEncoder?.endEncoding()

        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
