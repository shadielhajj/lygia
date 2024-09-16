#include "normal.glsl"
#include "cast.glsl"
#include "ao.glsl"
#include "softShadow.glsl"
#include "../shadingData/new.glsl"
#include "../../math/saturate.glsl"

/*
contributors: Patricio Gonzalez Vivo
description: |
    Material Constructor. Designed to integrate with GlslViewer's defines https://github.com/patriciogonzalezvivo/glslViewer/wiki/GlslViewer-DEFINES#material-defines
use:
    - void raymarchMaterial(in <vec3> ro, in <vec3> rd, out material _mat)
    - material raymarchMaterial(in <vec3> ro, in <vec3> rd)
options:
    - LIGHT_POSITION: in glslViewer is u_light
    - LIGHT_DIRECTION
    - LIGHT_COLOR
    - RAYMARCH_AMBIENT
    - RAYMARCH_SHADING_FNC(RAY, POSITION, NORMAL, ALBEDO)
examples:
    - /shaders/lighting_raymarching.frag
license:
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Prosperity License - https://prosperitylicense.com/versions/3.0.0
    - Copyright (c) 2021 Patricio Gonzalez Vivo under Patron License - https://lygia.xyz/license
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
    vec3 lig = normalize(LIGHT_DIRECTION);
    #else
    vec3 lig = normalize(LIGHT_POSITION - m.position);
    #endif
    
    vec3 rd = -shadingData.V;
    vec3 nor = m.normal;
    vec3 pos = m.position;
    vec3 lin = vec3(0.0);
    vec3 col = m.albedo.rgb * 0.2;
    float occ = raymarchAO(m.position, m.normal);
    float ks = 1.0;
    vec3 ref = reflect( rd, nor );

    // sun
    {
        vec3  hal = normalize( lig-rd );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        dif *= raymarchSoftShadow( pos, lig );
        float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0);
        spe *= dif;
        spe *= 0.04+0.96*pow(clamp(1.0-dot(hal,lig),0.0,1.0),5.0);
        lin += col*2.20*dif*vec3(1.30,1.00,0.70);
        lin += 5.00*spe*vec3(1.30,1.00,0.70)*ks;
    }
    // sky
    {
        float dif = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        dif *= occ;
        float spe = smoothstep( -0.2, 0.2, ref.y );
        spe *= dif;
        spe *= 0.04+0.96*pow(clamp(1.0+dot(nor,rd),0.0,1.0), 5.0 );
        spe *= raymarchSoftShadow( pos, ref );
        lin += col*0.60*dif*vec3(0.40,0.60,1.15);
        lin += 2.00*spe*vec3(0.40,0.60,1.30)*ks;
    }
    // back
    {
        float dif = clamp( dot( nor, normalize(vec3(0.5,0.0,0.6))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        dif *= occ;
        lin += col*0.55*dif*vec3(0.25,0.25,0.25);
    }
    // sss
    {
        float dif = pow(clamp(1.0+dot(nor,rd),0.0,1.0),2.0);
        dif *= occ;
        lin += col*0.25*dif*vec3(1.00,1.00,1.00);
    }
    
    col = lin;

    return vec4(col, m.albedo.a);
}

#endif