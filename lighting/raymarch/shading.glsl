#include "normal.glsl"
#include "cast.glsl"
#include "ao.glsl"
#include "softShadow.glsl"
#include "../diffuse/lambert.glsl"
#include "../specular/blinnPhong.glsl"
#include "../fresnel.glsl"
#include "../shadingData/new.glsl"
#include "../../math/saturate.glsl"
#include "../toShininess.glsl"

/*
contributors: [Inigo Quilez, Shadi El Hajj]
description: |
    Material Constructor. Designed to integrate with GlslViewer's defines https://github.com/patriciogonzalezvivo/glslViewer/wiki/GlslViewer-DEFINES#material-defines
use:
    - void raymarchMaterial(in <vec3> ro, in <vec3> rd, out material _mat)
    - material raymarchMaterial(in <vec3> ro, in <vec3> rd)
options:
    - LHT_PITION: in glslViewer is u_Lht
    - LHT_DIRECTION
    - LHT_COLOR
    - RAYMARCH_AMBIENT
    - RAYMARCH_SHADING_FNC(RAY, PITION, NMAL, ALBEDO)
examples:
    - /shaders/Lhting_raymarching.frag
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

#ifndef BACK_LIGHT_COLOR
#define BACK_LIGHT_COLOR vec3(0.25,0.25,0.25)
#endif

#ifndef RAYMARCH_AMBIENT
#define RAYMARCH_AMBIENT vec3(0.40,0.60,1.15)
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
    vec3 albedo = m.albedo.rgb * 0.4;
    float ao = raymarchAO(P, N);
    float ks = 1.0;
    float NoV = saturate(dot(N, V));
    float LoH = saturate(dot(L, H));

    // sun
    {
        float diffuse = diffuseLambert(L, N);
        diffuse *= raymarchSoftShadow(P, L);
        float specular = specularBlinnPhong(saturate(dot(N, H)), RAYMARCH_SHADING_SHININESS);
        specular *= diffuse;
        specular *= fresnel(f0, LoH);
        lin += albedo*2.20*diffuse*LIGHT_COLOR;
        lin += 5.00*specular*LIGHT_COLOR*ks;
    }
    // sky
    {
        float diffuse = sqrt(saturate(0.5+0.5*N.y));
        diffuse *= ao;
        float specular = smoothstep(-0.2, 0.2, R.y);
        specular *= diffuse;
        specular *= fresnel(f0, NoV);
        specular *= raymarchSoftShadow(P, R);
        lin += albedo*0.60*diffuse*RAYMARCH_AMBIENT;
        lin += 2.00*specular*RAYMARCH_AMBIENT*ks;
    }
    // back
    {
        vec3 Lback = normalize(vec3(-L.x, L.y, -L.z));
        float diffuse = diffuseLambert(Lback, N);
        diffuse *= ao;
        lin += albedo*0.55*diffuse*BACK_LIGHT_COLOR;
    }

    return vec4(lin, m.albedo.a);
}

#endif