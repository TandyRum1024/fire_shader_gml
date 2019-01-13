//
// Simple passthrough vertex shader
//
attribute vec3 in_Position;                  // (x,y,z)
//attribute vec3 in_Normal;                  // (x,y,z)     unused in this shader.	
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Disintegration shader
// Original :
// https://cafe.naver.com/playgm/98574
// 
// #define USE_EXTERNAL_TEXTURE
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D u_texture; // Noise tex
uniform float u_intensity; // intensity [0..1] -- 1 means fully burnt away and 0 means totally fine
uniform float u_time; // time for crackling effect on edges

// Fractional Brownian motion noise by Inigo Quilez
// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
const mat2 m2 = mat2(0.8,-0.6,0.6,0.8);
float rand(vec2 n) { 
return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float noise(vec2 n) {
const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}
float fbm( in vec2 p ){
    float f = 0.0;
    f += 0.5000*noise( p ); p = m2*p*2.02;
    f += 0.2500*noise( p ); p = m2*p*2.03;
    f += 0.1250*noise( p ); p = m2*p*2.01;
    f += 0.0625*noise( p );

    return f/0.9375;
}
////

void main()
{
    vec4 colorChar = vec4(0.23, 0.22, 0.20, 1.0);
    vec4 colorBurn = vec4(0.71, 0.08, 0.0, 1.0);
    vec4 colorAmber = vec4(0.95, 0.46, 0.1, 1.0);
    
    vec4 original = v_vColour * texture2D( gm_BaseTexture, v_vTexcoord );
    vec4 composite = original;
    float alpha = composite.a;
    float microwave_chan_meat_spin = 0.0;
    
    // yo noise
    #ifdef USE_EXTERNAL_TEXTURE
        microwave_chan_meat_spin = texture2D(u_texture, fract(v_vTexcoord)).r;
    #else
        microwave_chan_meat_spin = fbm(v_vTexcoord * 40.0);
    #endif
    
    float delta = max(u_intensity - microwave_chan_meat_spin, 0.0);
    float interp = smoothstep(microwave_chan_meat_spin, 1.0, u_intensity + microwave_chan_meat_spin);
    
    // gradient stops
    float stepChar = 0.1;
    float stepCharEnd = 0.75;
    float stepAmber = 0.95 + sin(u_time * 0.22) * 0.02;
    float stepFull = 0.98 + cos(u_time * 0.42 + 42.0) * 0.01;
    float stepLimit = min(1.0 + cos(u_time * 0.52 + 21.0) * 0.01, 1.0);
    
    // mix colour
    composite = mix(composite, composite * colorChar, smoothstep(stepChar, stepCharEnd, interp));
    composite = mix(composite, min(composite + colorBurn, 1.0), smoothstep(stepCharEnd, stepAmber, interp));
    composite = mix(composite, min(original + colorAmber, 1.0), smoothstep(stepAmber, stepFull, interp));
    composite = mix(composite, vec4(0.0), smoothstep(stepFull, stepLimit, interp));
    
    composite.a = min(alpha, composite.a);
    gl_FragColor = composite;
}

