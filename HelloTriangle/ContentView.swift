//
//  ContentView.swift
//  HelloTriangle
//
//  Created by Just aLoli on 2024/6/28.
//

import SwiftUI
import MetalKit

struct ContentView: NSViewRepresentable {
    func makeCoordinator() -> Renderer {
        return Renderer(self);
    }
    
    func makeNSView(context: NSViewRepresentableContext<ContentView>) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator;
        mtkView.preferredFramesPerSecond = 60;
        mtkView.enableSetNeedsDisplay = true;
        if let metalDevice = MTLCreateSystemDefaultDevice(){
            mtkView.device = metalDevice
        }
        
        mtkView.framebufferOnly = false;
        mtkView.drawableSize = mtkView.frame.size;
        mtkView.isPaused = false;
        return mtkView
        
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<ContentView>) {
        
    }
    
}

#Preview {
    ContentView()
}
