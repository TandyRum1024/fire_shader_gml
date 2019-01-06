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
// 불 이펙트 : 일반
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    // 255, 152, 56
    vec4 colorCore = vec4(1.0, 0.59, 0.21, 1.0);
    // 255, 84, 0
    vec4 colorMid = vec4(1.0, 0.32, 0.0, 1.0);
    // 188, 25, 0
    vec4 colorAmber = vec4(0.73, 0.22, 0.0, 0.5);
    // 99, 9, 0
    vec4 colorSmoke = vec4(0.18, 0.13, 0.13, 0.0);
    
    vec4 final = vec4(0.0);
    float lum = texture2D( gm_BaseTexture, v_vTexcoord ).r;
    
    // Step gradient from https://stackoverflow.com/questions/15935117/how-to-create-multiple-stop-gradient-fragment-shader
	float stepLow = 0.0;
	float stepMidStart = 0.35;
	float stepMidEnd = 0.95;
	float stepHigh = 1.0;
	
	final = mix(colorSmoke, colorAmber, smoothstep(stepLow, stepMidStart, lum));
	final = mix(final, colorMid, smoothstep(stepMidStart, stepMidEnd, lum));
	final = mix(final, colorCore, smoothstep(stepMidEnd, stepHigh, lum));
    
    gl_FragColor = v_vColour * final;
    // gl_FragColor = vec4(vec3(texture2D( gm_BaseTexture, v_vTexcoord ).r), 1.0);
}

