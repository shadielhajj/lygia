#include "envMap.hlsl"
#include "common/envBRDFApprox.hlsl"

/*
contributors: Shadi El Hajj
description: Calculate the transmission component.
use:
    - <float3> refraction(<Material> mat, <ShadingData> shadingData)
license: MIT License (MIT) Copyright (c) 2024 Shadi El Hajj
*/

#ifndef IBL_LUMINANCE
#define IBL_LUMINANCE   1.0
#endif

#ifndef FNC_REFRACTION
#define FNC_REFRACTION

void refractionSolidSphere(Material mat, ShadingData shadingData, out float3 direction) {

    const float thickness = 1.0;
    const float airIor = 1.0;
    float3 etaIR = airIor / mat.ior;
    float3 etaRI = mat.ior / airIor;
    float3 r = -shadingData.V;
    r = refract(r, mat.normal, etaIR);
    float NoR = dot(mat.normal, r);
    float d = thickness * -NoR;
    float3 n1 = normalize(NoR * r - mat.normal * 0.5);
    direction = refract(r, n1,  etaRI);
}

float3 refraction(Material mat, ShadingData shadingData) {

    float3 direction = float3(0.0, 0.0, 0.0);
    refractionSolidSphere(mat, shadingData, direction);

    const float airIor = 1.0;
    float3 etaIR = airIor / mat.ior;
    float perceptualRoughness = lerp(mat.roughness, 0.0, saturate(etaIR * 3.0 - 2.0));

    float3 Ft = envMap(direction, perceptualRoughness) * IBL_LUMINANCE;
    Ft *= shadingData.diffuseColor;

    float2 E = envBRDFApprox(shadingData.NoV, shadingData.roughness);    
    float3 specularColorE = shadingData.specularColor * E.x + E.y;
    Ft *= 1.0 - specularColorE;

    return Ft;
}

#endif
