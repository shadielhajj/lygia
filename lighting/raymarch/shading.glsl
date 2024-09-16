#include "normal.glsl"
#include "cast.glsl"
#include "ao.glsl"
#include "softShadow.glsl"
#include "../diffuse/lambert.glsl"
#include "../specular/blinnPhong.glsl"
#include "../fresnel.glsl"
#include "../shadingData/new.glsl"
#include "../../math/saturate.glsl"

/*
contributors: [Inigo Quilez, Shadi El Hajj]
description: |
    Default raymarching shading function. Based on IQ's outdoors 3-point rig described in https://iquilezles.org/articles/outdoorslighting/ and implemented in https://www.shadertoy.com/view/Xds3zN
use:
    - void raymarchDefaultShading(<Material> m, <ShadingData> shadingData)
examples:
    - /shaders/lighting_raymarching.frag
license:
    - MIT License (MIT) Copyright (c) 2013 Inigo Quilez
    - MIT License (MIT) Copyright (c) 2024 Shadi El Hajj
*/

#ifndef LIGHT_POSITION
#define LIGHT_POSITION vec3(0.0, 10.0, -50.0)
#endif

#ifndef LIGHT_COLOR
#define LIGHT_COLOR vec3(1.30,1.00,0.70)
#endif

#ifndef LIGHT_DIFFUSE_INTENSITY
#define LIGHT_DIFFUSE_INTENSITY 2.2*0.3
#endif

#ifndef LIGHT_SPECULAR_INTENSITY
#define LIGHT_SPECULAR_INTENSITY 5.0
#endif

#ifndef BACK_LIGHT_COLOR
#define BACK_LIGHT_COLOR vec3(0.25,0.25,0.25)
#endif

#ifndef BACK_LIGHT_DIFFUSE_INTENSITY
#define BACK_LIGHT_DIFFUSE_INTENSITY 0.55*0.3
#endif

#ifndef RAYMARCH_AMBIENT
#define RAYMARCH_AMBIENT vec3(0.40,0.60,1.15)
#endif

#ifndef AMBIENT_DIFFUSE_INTENSITY
#define AMBIENT_DIFFUSE_INTENSITY 0.6*0.3
#endif

#ifndef AMBIENT_SPECULAR_INTENSITY
#define AMBIENT_SPECULAR_INTENSITY 2.0
#endif

#ifndef RAYMARCH_SHADING_SHININESS
#define RAYMARCH_SHADING_SHININESS 16.0
#endif 

#ifndef RAYMARCH_SHADING_FNC
#define RAYMARCH_SHADING_FNC raymarchDefaultShading
#endif

#ifndef FNC_RAYMARCH_DEFAULTSHADING
#define FNC_RAYMARCH_DEFAULTSHADING

vec4 raymarchDefaultShading(Material m, ShadingData shadingData) {

    #if defined(LIGHT_DIRECTION)
    vec3 L = normalize(LIGHT_DIRECTION);
    #else
    vec3 L = normalize(LIGHT_POSITION - m.position);
    #endif
    
    const float f0 = 0.04;
    vec3 V = shadingData.V;
    vec3 H = normalize(L+V);
    vec3 N = m.normal;
    vec3 P = m.position;
    vec3 R = reflect(-V, N);
    vec3 lin = vec3(0.0);
    vec3 albedo = m.albedo.rgb;
    float ao = raymarchAO(P, N);
    float NoV = saturate(dot(N, V));
    float LoH = saturate(dot(L, H));

    // sun
    {
        float diffuse = diffuseLambert(L, N);
        diffuse *= raymarchSoftShadow(P, L);
        float specular = specularBlinnPhong(saturate(dot(N, H)), RAYMARCH_SHADING_SHININESS);
        specular *= diffuse;
        specular *= fresnel(f0, LoH);
        lin += albedo*diffuse*LIGHT_COLOR*LIGHT_DIFFUSE_INTENSITY;
        lin += specular*LIGHT_COLOR*LIGHT_SPECULAR_INTENSITY;
    }
    // sky
    {
        float diffuse = sqrt(saturate(0.5+0.5*N.y));
        diffuse *= ao;
        float specular = smoothstep(-0.2, 0.2, R.y);
        specular *= diffuse;
        specular *= fresnel(f0, NoV);
        specular *= raymarchSoftShadow(P, R);
        lin += albedo*diffuse*RAYMARCH_AMBIENT*AMBIENT_DIFFUSE_INTENSITY;
        lin += specular*RAYMARCH_AMBIENT*AMBIENT_SPECULAR_INTENSITY;
    }
    // back
    {
        vec3 Lback = normalize(vec3(-L.x, L.y, -L.z));
        float diffuse = diffuseLambert(Lback, N);
        diffuse *= ao;
        lin += albedo*diffuse*BACK_LIGHT_COLOR*BACK_LIGHT_DIFFUSE_INTENSITY;
    }

    return vec4(lin, m.albedo.a);
}

#endif