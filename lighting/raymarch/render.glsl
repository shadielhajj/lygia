#include "cast.glsl"
#include "ao.glsl"
#include "normal.glsl"
#include "softShadow.glsl"
#include "../../math/saturate.glsl"

/*
author:  Inigo Quiles
description: raymarching renderer
use: <vec4> raymarchRender( in <vec3> ro, in <vec3> rd ) 
options:
    - RAYMARCH_MATERIAL_FNC(RGB) vec3(RGB)
    - #define RAYMARCH_BACKGROUND vec3(0.0)
    - RAYMARCH_AMBIENT vec3(1.0)
    - LIGHT_COLOR     vec3(0.5)
    - LIGHT_POSITION  vec3(0.0, 10.0, -50.0)
license: |
    The MIT License
    Copyright © 2013 Inigo Quilez
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    https://www.youtube.com/c/InigoQuilez
    https://iquilezles.org/

    A list of useful distance function to simple primitives. All
    these functions (except for ellipsoid) return an exact
    euclidean distance, meaning they produce a better SDF than
    what you'd get if you were constructing them from boolean
    operations (such as cutting an infinite cylinder with two planes).

    List of other 3D SDFs:
       https://www.shadertoy.com/playlist/43cXRl
    and
       http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
*/

#ifndef LIGHT_POSITION
#define LIGHT_POSITION  vec3(0.0, 10.0, -50.0)
#endif

#ifndef LIGHT_COLOR
#define LIGHT_COLOR     vec3(0.5)
#endif

#ifndef RAYMARCH_AMBIENT
#define RAYMARCH_AMBIENT vec3(1.0)
#endif

#ifndef RAYMARCH_BACKGROUND
#define RAYMARCH_BACKGROUND vec3(0.0)
#endif

#ifndef RAYMARCH_MATERIAL_FNC
#define RAYMARCH_MATERIAL_FNC raymarchRender
#endif

#ifndef FNC_RAYMARCHRENDER
#define FNC_RAYMARCHRENDER

vec3 raymarchRender(vec3 rd, vec3 pos, vec3 nor, vec3 alb) {
    if ( alb.r + alb.g + alb.b > 0.0 ) 
        return alb;

    vec3 color = alb;
    vec3 ref = reflect( rd, nor );
    float occ = raymarchAO( pos, nor );
    vec3  lig = normalize( LIGHT_POSITION );
    vec3  hal = normalize( lig-rd );
    float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
    float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
    float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
    float dom = smoothstep( -0.1, 0.1, ref.y );
    float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
    
    dif *= raymarchSoftShadow( pos, lig, 0.02, 2.5 );
    dom *= raymarchSoftShadow( pos, ref, 0.02, 2.5 );

    vec3 lin = vec3(0.0);
    lin += 1.30 * dif * LIGHT_COLOR;
    lin += 0.40 * amb * occ * RAYMARCH_AMBIENT;
    lin += 0.50 * dom * occ * RAYMARCH_AMBIENT;
    lin += 0.50 * bac * occ * 0.25;
    lin += 0.25 * fre * occ;

    return color * lin;
}

vec4 raymarchRender( in vec3 ro, in vec3 rd ) { 
    vec3 col = vec3(0.0);
    col = RAYMARCH_BACKGROUND;

    vec4 res = raymarchCast(ro, rd);
    float t = res.a;

    // if ( res.r + res.g + res.b > 0.0 ) 
    {
        vec3 pos = ro + t * rd;
        vec3 nor = raymarchNormal( pos );
        col = RAYMARCH_MATERIAL_FNC(rd, pos, nor, res.rgb);
    }

    return vec4( saturate(col), t );
}

#endif