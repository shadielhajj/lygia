#include "envMap.hlsl"
#include "ior/2eta.hlsl"

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

float3 refractionSolidSphere(Material mat, ShadingData shadingData) {

    const float thickness = 1.0;
    float3 eta = ior2eta(mat.ior);
    float3 r = refract(-shadingData.V, mat.normal, eta);
    float NoR = dot(mat.normal, r);
    float d = thickness * -NoR;
    float3 n1 = normalize(NoR * r - mat.normal * 0.5);
    return refract(r, n1,  mat.ior);
}

float3 refraction(Material mat, ShadingData shadingData) {

    float3 direction = refractionSolidSphere(mat, shadingData);
    float3 eta = ior2eta(mat.ior);
    float perceptualRoughness = lerp(mat.roughness, 0.0, saturate(eta * 3.0 - 2.0));

    float3 Ft = envMap(direction, perceptualRoughness) * IBL_LUMINANCE;
    Ft *= shadingData.diffuseColor;
    Ft *= 1.0 - shadingData.specularColorE;

    return Ft;
}

#endif
