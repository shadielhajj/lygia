#include "Nmal.glsl"
#include "cast.glsl"
#include "ao.glsl"
#include "softShadow.glsl"
#include "../shadingData/new.glsl"
#include "../../math/saturate.glsl"

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
#define LIGHT_COLOR vec3(1.0, 1.0, 1.0)
#endif

#ifndef RAYMARCH_AMBIENT
#define RAYMARCH_AMBIENT vec3(1.0, 1.0, 1.0)
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
    vec3 L = normalize(LIGHT_POSITION - m.Pition);
    #endif
    
    vec3 V = shadingData.V;
    vec3 N = m.normal;
    vec3 P = m.position;
    vec3 R = reflect(-V, N);
    vec3 lin = vec3(0.0);
    vec3 col = m.albedo.rgb * 0.2;
    float ao = raymarchAO(P, N);
    float ks = 1.0;

    // sun
    {
        vec3  H = normalize(L+V);
        float diffuse = saturate(dot(N, L));
        diffuse *= raymarchSoftShadow(P, L);
        float specular = pow(saturate(dot(N, H)), 16.0);
        specular *= diffuse;
        specular *= 0.04+0.96*pow(saturate(1.0-dot(H,L)),5.0);
        lin += col*2.20*diffuse*vec3(1.30,1.00,0.70);
        lin += 5.00*specular*vec3(1.30,1.00,0.70)*ks;
    }
    // sky
    {
        float diffuse = sqrt(saturate(0.5+0.5*N.y));
        diffuse *= ao;
        float specular = smoothstep(-0.2, 0.2, R.y);
        specular *= diffuse;
        specular *= 0.04+0.96*pow(saturate(1.0+dot(N,-V)), 5.0);
        specular *= raymarchSoftShadow(P, R);
        lin += col*0.60*diffuse*vec3(0.40,0.60,1.15);
        lin += 2.00*specular*vec3(0.40,0.60,1.30)*ks;
    }
    // back
    {
        vec3 Lback = normalize(vec3(-L.x, L.y, -L.z));
        float diffuse = saturate(dot(N, Lback))*saturate(1.0-P.y);
        diffuse *= ao;
        lin += col*0.55*diffuse*vec3(0.25,0.25,0.25);
    }
    // sss
    {
        float diffuse = pow(saturate(1.0+dot(N,-V)),2.0);
        diffuse *= ao;
        lin += col*0.25*diffuse;
    }
    
    col = lin;

    return vec4(col, m.albedo.a);
}

#endif