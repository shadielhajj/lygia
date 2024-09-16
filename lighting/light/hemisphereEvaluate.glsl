/*
contributors: Shadi El Hajj
description: Calculate hermisphere light. Based on the model described in OpenGL Programming Guide (8th edition), Chapter 8. 
use: void lightHemisphereEvaluate(<vec3> normal, out <vec3> Fd)
license: MIT License (MIT) Copyright (c) 2024 Shadi El Hajj
*/

#ifndef LIGHT_HEMISPHERE_DIRECTION
#define LIGHT_HEMISPHERE_DIRECTION vec3(0.0, -1.0, 0.0)
#endif

#ifndef LIGHT_HEMISPHERE_GROUND_COLOR
#define LIGHT_HEMISPHERE_GROUND_COLOR vec3(1.0)
#endif

#ifndef LIGHT_HEMISPHERE_SKY_COLOR
#define LIGHT_HEMISPHERE_SKY_COLOR vec3(0.3)
#endif

#ifndef FNC_LIGHT_HEMISPHERE_EVALUATE
#define FNC_LIGHT_HEMISPHERE_EVALUATE

void lightHemisphereEvaluate(vec3 normal, out vec3 Fd) {
    float NoL = dot(normal, LIGHT_HEMISPHERE_DIRECTION);
    float a = NoL * 0.5 + 0.5;
    Fd = mix(LIGHT_HEMISPHERE_GROUND_COLOR, LIGHT_HEMISPHERE_SKY_COLOR, a);
}

#endif