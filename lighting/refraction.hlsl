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

float3 refractionSolidSphere(float3 n, float3 v, float3 ior) {

    const float thickness = 1.0;
    float3 r = refract(-v, n, 1.0/ior);
    float NoR = dot(n, r);
    float d = thickness * -NoR;
    float3 n1 = normalize(NoR * r - n * 0.5);
    return refract(r, n1,  ior);
}

float3 refractionSample(float3 n, float3 v, float roughness, float ior) {
    float perceptualRoughness = lerp(roughness, 0.0, saturate((1.0/ior) * 3.0 - 2.0));
    float3 direction = refractionSolidSphere(n, v, ior);
    return envMap(direction, perceptualRoughness);
}

float3 refraction(Material mat, ShadingData shadingData) {

    const float dispersion = 0.05;
    float halfSpread = (mat.ior.g - 1.0) * 0.025 * dispersion;
    float3 iors = float3(mat.ior.g - halfSpread, mat.ior.g, mat.ior.g + halfSpread);

    float3 Ft = float3(0.0, 0.0, 0.0);
    Ft.r = refractionSample(mat.normal, shadingData.V, mat.roughness, iors.r).r;
    Ft.g = refractionSample(mat.normal, shadingData.V, mat.roughness, iors.g).g;
    Ft.b = refractionSample(mat.normal, shadingData.V, mat.roughness, iors.b).b;

    Ft *= IBL_LUMINANCE;
    Ft *= shadingData.diffuseColor;
    Ft *= 1.0 - shadingData.specularColorE;

    return Ft;
}

#endif
