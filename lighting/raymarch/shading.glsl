#include "normal.glsl"
#include "cast.glsl"
#include "ao.glsl"
#include "softShadow.glsl"
#include "../diffuse/lambert.glsl"
#include "../specular/blinnPhong.glsl"
#include "../fresnel.glsl"
#include "../shadingData/new.glsl"
#include "../../math/saturate.glsl"
#include "../light/hemisphereEvaluate.glsl"

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
// #define LIGHT_COLOR vec3(1.30,1.00,0.70)
#define LIGHT_COLOR vec3(1.0, 1.0, 1.0)
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
//#define RAYMARCH_AMBIENT vec3(0.40,0.60,1.15)
#define RAYMARCH_AMBIENT vec3(0.6, 0.6, 0.6)
#endif

#ifndef AMBIENT_DIFFUSE_INTENSITY
#define AMBIENT_DIFFUSE_INTENSITY 0.6*0.3
#endif

#ifndef AMBIENT_SPECULAR_INTENSITY
#define AMBIENT_SPECULAR_INTENSITY 0.5
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
    vec3 albedo = m.albedo.rgb;
    float ao = m.ambientOcclusion;
    vec3 V = shadingData.V;
    vec3 H = normalize(L+V);
    vec3 N = m.normal;
    vec3 P = m.position;
    vec3 R = reflect(-V, N);
    float NoV = saturate(dot(N, V));
    float LoH = saturate(dot(L, H));
    vec3 result = vec3(0.0, 0.0, 0.0);

    // sun
    {
        float diffuse = diffuseLambert(L, N);
        diffuse *= raymarchSoftShadow(P, L);
        result += albedo*diffuse*LIGHT_COLOR*LIGHT_DIFFUSE_INTENSITY;

        float specular = specularBlinnPhong(saturate(dot(N, H)), RAYMARCH_SHADING_SHININESS);
        specular *= diffuse;
        specular *= fresnel(f0, LoH);
        result += specular*LIGHT_COLOR*LIGHT_SPECULAR_INTENSITY;
    }
    // sky
    {
        vec3 diffuse = vec3(0.0, 0.0, 0.0);
        lightHemisphereEvaluate(N, diffuse);
        diffuse *= ao;
        result += albedo*diffuse*AMBIENT_DIFFUSE_INTENSITY;

        vec3 specular = smoothstep(-0.2, 0.2, R.y) * vec3(1.0, 1.0, 1.0);
        specular *= diffuse;
        specular *= fresnel(f0, NoV);

        Material ref = raymarchCast(P, R);
        if (ref.valid) {
            specular *= ref.albedo.rgb * diffuseLambert(L, N) * LIGHT_COLOR * LIGHT_DIFFUSE_INTENSITY;
        }

        result += specular*RAYMARCH_AMBIENT*AMBIENT_SPECULAR_INTENSITY;
    }
    // back
    {
        vec3 Lback = normalize(vec3(-L.x, L.y, -L.z));
        float diffuse = diffuseLambert(Lback, N);
        diffuse *= ao;
        result += albedo*diffuse*BACK_LIGHT_COLOR*BACK_LIGHT_DIFFUSE_INTENSITY;
    }

    return vec4(result, m.albedo.a);
}

#endif