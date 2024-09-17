#include "normal.hlsl"
#include "cast.hlsl"
#include "ao.hlsl"
#include "softShadow.hlsl"
#include "../shadingData/new.hlsl"

/*
contributors: Patricio Gonzalez Vivo
description: |
    Material Constructor. Designed to integrate with GlslViewer's defines https://github.com/patriciogonzalezvivo/glslViewer/wiki/GlslViewer-DEFINES#material-defines
use:
    - void raymarchMaterial(in <float3> ro, in <float3> rd, out material _mat)
    - material raymarchMaterial(in <float3> ro, in <float3> rd)
options:
    - LIGHT_POSITION: in glslViewer is u_light
    - LIGHT_DIRECTION
    - LIGHT_COLOR
    - RAYMARCH_AMBIENT
    - RAYMARCH_SHADING_FNC(RAY, POSITION, NORMAL, ALBEDO)
license:
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Prosperity License - https://prosperitylicense.com/versions/3.0.0
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Patron License - https://lygia.xyz/license
*/

#ifndef LIGHT_POSITION
#define LIGHT_POSITION float3(0.0, 10.0, -50.0)
#endif

#ifndef LIGHT_COLOR
#define LIGHT_COLOR float3(1.0, 1.0, 1.0)
#endif

#ifndef RAYMARCH_AMBIENT
#define RAYMARCH_AMBIENT float3(1.0, 1.0, 1.0)
#endif

#ifndef RAYMARCH_SHADING_FNC
#define RAYMARCH_SHADING_FNC raymarchDefaultShading
#endif

#ifndef FNC_RAYMARCH_DEFAULTSHADING
#define FNC_RAYMARCH_DEFAULTSHADING

float4 raymarchDefaultShading(Material m, ShadingData shadingData) {

    float3 N = m.normal;
    float3 P = m.position;
    float3 V = shadingData.V;

    #if defined(LIGHT_DIRECTION)
    float3 L = normalize(LIGHT_DIRECTION);
    #else
    float3 L = normalize(LIGHT_POSITION - P);
    #endif
    
    float3 R = reflect(-V, N);
    float ao = raymarchAO(P, N);

    float3 H = normalize(L + V);
    // sky light: replace the sky dome with a single directional light falling straight vertically on the set. 
    float sky = saturate(0.5 + 0.5 * N.y);
    float NoL = saturate(dot(N, L));
    // Since the main soure of indirect light is the bounce of the sun light into the scene itself being
    // reflected back in the oposite direction it was coming from (in overall), we can simply put a third
    // and last directional light coming from aproximately the oposite direction of the sun.
    // This light we will make it horizontal,so we are basically making copying the two horizontal coordinates
    // of the sun direction and negating them, and leaving the vertical dimension to zero.
    float back = saturate(dot(N, normalize(float3(-L.x, 0.0, -L.z)))) * saturate(1.0 - P.y);
    float dom = smoothstep( -0.1, 0.1, R.y );
    float fre = pow(saturate(1.0 + dot(N, -V)), 2.0);
    
    NoL *= raymarchSoftShadow(m.position, L);
    dom *= raymarchSoftShadow(m.position, R);

    float3 env = RAYMARCH_AMBIENT;
    float3 shade = float3(0.0, 0.0, 0.0);
    //shade += 1.30 * NoL * LIGHT_COLOR; // key light
    //shade += 0.40 * sky * ao * env; // sky light
    shade += 0.50 * dom * ao * env;
    //shade += 0.50 * back * ao * 0.25; // back light (indirect light)
    //shade += 0.25 * fre * ao;

    return float4(m.albedo.rgb * shade, m.albedo.a);
}

#endif