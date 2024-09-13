//
//  definitions.h
//  HelloTriangle
//
//  Created by Just aLoli on 2024/6/28.
//

#ifndef definitions_h
#define definitions_h

#include <simd/simd.h>

struct Vertex {
    vector_float2 position;
    vector_float4 color;
};

struct Uniforms {
    float frameNumber;
    float elapsedTime;
    vector_float2 iResolution;
};

#endif /* definitions_h */
