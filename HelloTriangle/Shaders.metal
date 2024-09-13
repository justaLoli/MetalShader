//
//  Shaders.metal
//  HelloTriangle
//
//  Created by Just aLoli on 2024/6/28.
//

#define vec2 float2
#define vec3 float3
#define vec4 float4
#define mat2 float2x2
#define mod fmod

#include <metal_stdlib>
using namespace metal;

#include "definitions.h"

struct Fragment{
    float4 position [[position]];
    float4 color;
};

vertex Fragment vertexShader(const device Vertex *vertexArray[[buffer(0)]], unsigned int vid [[vertex_id]]) {
    Vertex input = vertexArray[vid];
    
    Fragment output;
    output.position = float4(input.position.x, input.position.y, 0, 1);
    output.color = input.color;
    
    return output;
}
//-----------------------------------------------------------------
//THE SHADER PART
//-----------------------------------------------------------------

mat2 rot2D(float angle){
    float a = sin(angle);
    float b = cos(angle);
    return mat2(b,-a,a,b);
}
float sdSphere(vec3 p, float R){
    //the Sphere SDF function.
    //the P is the input point, and R defines the radius of the sphere.
    //initially, we assume the sphere is at the origin. this can be shifted
    //if one call this function with p minus something.
    return length(p) - R;
}
float sdBox(vec3 p, vec3 b){
    //b代表长宽高 **的一半**
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float smin(float a,float b,float k){
    float h = max( k - abs(a-b),0.) / k;
    return min(a,b) - h*h*h*k*(1./6.);
}
float dist(vec3 p,float iTime){
    vec3 sphere_pos = vec3(cos(iTime) * 2.,0,sin(iTime) * 2.);
    float sphere = sdSphere(p - sphere_pos, .7);
    //scaling: 因为我们送进去的是p的倍数，除了等于0的点（图形边界）有变，其它地方，
    //得到的距离的量级也会放大，导致raymarch的算法用的距离不太对。
    //float box = sdBox(p * 2.,vec3(.7)) / 2.;
    //因此最后还要缩小一下
    //分型：对输入p进行取模，可复制框内结果
    //比如去p的小数部分参与运算。不过sdbox在0-1，0-1，0-1只有一部分体积，因此在取小数后移动，
    //使得复制单元包含整个方块
    vec3 q = p;
    //q = (fract(p*0.5) - .5)/.5; // no need, use mod func instead.
    q.z += iTime * .4;
    q.xy = (mod(q.xy + 14,0.7) - .35);
    q.z = (mod(q.z + 10,0.5) - .25);
    
    float box = sdBox(q,vec3(.1));
    float ground = p.y + 0.7;
    
    float res;
    res = min(smin(sphere,box,.7),ground);
    
    return res;
}
float4 mainImage(float2 fragCoord, constant Uniforms& uniforms){
    float2 iResolution = uniforms.iResolution;
    vec2 uv = (fragCoord * 2. - iResolution.xy) / iResolution.y;
       
//    vec2 mouse = (iMouse.xy * 2. - iResolution.xy) / iResolution.y + vec2(0.,-.5);
    float2 mouse;
    mouse.x = uniforms.elapsedTime * .0;
    mouse.y = .1;
    //camera init
    vec3 ro = vec3(0,.5,-3);
    vec3 rd = normalize(vec3(uv,2));
//    ro.yz *= float2x2(1,0,0,1);
    ro.yz = rot2D(-mouse.y) * ro.yz;
    rd.yz = rot2D(-mouse.y) * rd.yz;
    //对镜头施加
    //旋转：射线起点旋转，方向一并旋转（因此照片始终对着图像中心）
    ro.xz = rot2D(-mouse.x) * ro.xz;
    rd.xz = rot2D(-mouse.x) * rd.xz;
    //color init
    vec3 col = vec3(0);
    //distance init
    float t = 0.;

    //raymarching
    int i;
    for(i=0;;i++){
       vec3 p = ro + t * rd;
       float d = dist(p,uniforms.elapsedTime);
       t += d;
       if(d < 0.001 || t >10.) break;
    }

    col = vec3(t * 0.2 - float(i) * 0.002);
    float4 fragColor = vec4(col,1);
    return fragColor;
}


fragment float4 fragmentShader(Fragment input [[stage_in]],
                               constant Uniforms& uniforms [[buffer(1)]]) {
    
    vec2 fragCoord = input.position.xy;
    fragCoord.y = uniforms.iResolution.y-fragCoord.y;
    return mainImage(fragCoord,uniforms);
}

