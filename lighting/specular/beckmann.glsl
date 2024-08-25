#include "../common/beckmann.glsl"

#ifndef FNC_SPECULAR_BECKMANN
#define FNC_SPECULAR_BECKMANN

float specularBeckmann(ShadingData shadingData) {
    return beckmann(shadingData.NoH, shadingData.linearRoughness);
}

#endif