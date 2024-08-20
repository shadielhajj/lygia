#include "snoise.glsl"
#include "gnoise.glsl"


/*
contributors: Patricio Gonzalez Vivo
description: Fractal Brownian Motion
use: fbm(<vec2> pos)
options:
    FBM_OCTAVES: numbers of octaves. Default is 4.
    FBM_NOISE_FNC(UV): noise function to use Default 'snoise(UV)' (simplex noise)
    FBM_LACUNARITY: scalar. Defualt is 2.
    FBM_GAIN: amplitude scalar. Default is 0.5
examples:
    - /shaders/generative_fbm.frag
license:
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Prosperity License - https://prosperitylicense.com/versions/3.0.0
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Patron License - https://lygia.xyz/license
*/

#ifndef FBM_OCTAVES
#define FBM_OCTAVES 4
#endif

#ifndef FBM_NOISE_FNC
#define FBM_NOISE_FNC snoise
#endif

#ifndef FBM_NOISE2_FNC
#define FBM_NOISE2_FNC FBM_NOISE_FNC
#endif

#ifndef FBM_NOISE3_FNC
#define FBM_NOISE3_FNC FBM_NOISE_FNC
#endif

#ifndef FBM_NOISE4_FNC
#define FBM_NOISE4_FNC FBM_NOISE_FNC
#endif

#ifndef FBM_NOISE_TILABLE_FNC
#define FBM_NOISE_TILABLE_FNC(UV, TILE) gnoise(UV, TILE)
#endif

#ifndef FBM_NOISE3_TILABLE_FNC
#define FBM_NOISE3_TILABLE_FNC(UV, TILE) FBM_NOISE_TILABLE_FNC(UV, TILE)
#endif

#ifndef FBM_NOISE_TYPE
#define FBM_NOISE_TYPE float
#endif

#ifndef FBM_LACUNARITY
#define FBM_LACUNARITY 2.0
#endif

#ifndef FBM_GAIN
#define FBM_GAIN 0.5
#endif

#ifndef FNC_FBM
#define FNC_FBM

FBM_NOISE_TYPE fbm(in vec2 st) {
    // Initial values
    FBM_NOISE_TYPE value = 0.0;
    float amplitude = 1.0;

    // Loop of octaves
    for (int i = 0; i < FBM_OCTAVES; i++) {
        value += amplitude * FBM_NOISE2_FNC(st);
        st *= FBM_LACUNARITY;
        amplitude *= FBM_GAIN;
    }
    return value;
}

FBM_NOISE_TYPE fbm(in vec3 pos) {
    // Initial values
    FBM_NOISE_TYPE value = 0.0;
    float amplitude = 1.0;

    // Loop of octaves
    for (int i = 0; i < FBM_OCTAVES; i++) {
        value += amplitude * FBM_NOISE3_FNC(pos);
        pos *= FBM_LACUNARITY;
        amplitude *= FBM_GAIN;
    }
    return value;
}

FBM_NOISE_TYPE fbm(in vec4 pos) {
    // Initial values
    FBM_NOISE_TYPE value = 0.0;
    float amplitude = 1.0;

    // Loop of octaves
    for (int i = 0; i < FBM_OCTAVES; i++) {
        value += amplitude * FBM_NOISE4_FNC(pos);
        pos *= FBM_LACUNARITY;
        amplitude *= FBM_GAIN;
    }
    return value;
}

FBM_NOISE_TYPE fbm(vec3 p, float tileLength) {
    const float persistence = 0.5;
    const float lacunarity = 2.0;

    float amplitude = 0.5;
    FBM_NOISE_TYPE total = FBM_NOISE_TYPE(0.0);
    float normalization = 0.0;

    for (int i = 0; i < FBM_OCTAVES; ++i) {
        float noiseValue = FBM_NOISE3_TILABLE_FNC(p, tileLength * lacunarity * 0.5) * 0.5 + 0.5;
        total += noiseValue * amplitude;
        normalization += amplitude;
        amplitude *= persistence;
        p = p * lacunarity;
    }

    return total / normalization;
}
#endif
