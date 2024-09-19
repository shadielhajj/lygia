#include "envMap.glsl"
#include "ior/2eta.glsl"

/*
contributors: Shadi El Hajj
description: Calculate the transmission component.
use:
    - <vec3> refraction(<Material> mat, <ShadingData> shadingData)
license: MIT License (MIT) Copyright (c) 2024 Shadi El Hajj
*/

#ifndef IBL_LUMINANCE
#define IBL_LUMINANCE   1.0
#endif

#ifndef FNC_REFRACTION
#define FNC_REFRACTION

vec3 refractionSolidSphere(Material mat, ShadingData shadingData) {

    const float thickness = 1.0;
    vec3 eta = ior2eta(mat.ior);
    vec3 r = refract(-shadingData.V, mat.normal, eta);
    float NoR = dot(mat.normal, r);
    float d = thickness * -NoR;
    vec3 n1 = normalize(NoR * r - mat.normal * 0.5);
    return refract(r, n1,  mat.ior);
}

vec3 refraction(Material mat, ShadingData shadingData) {

    vec3 direction = refractionSolidSphere(mat, shadingData);
    vec3 eta = ior2eta(mat.ior);
    float perceptualRoughness = mix(mat.roughness, 0.0, saturate(eta * 3.0 - 2.0));

    vec3 Ft = envMap(direction, perceptualRoughness) * IBL_LUMINANCE;
    Ft *= shadingData.diffuseColor;
    Ft *= 1.0 - shadingData.specularColorE;

    return Ft;
}

#endif
