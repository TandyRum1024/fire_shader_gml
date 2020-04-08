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
// Fire effect : Trippy dithered flame
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;
uniform vec2 u_texelsize;
uniform vec2 u_bayertexelsize;
uniform sampler2D u_bayer;

// Original HSV to RBG routine from
// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 hsv2rgb (vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Fetches dithering texture
float getDitherAt (vec2 uv)
{
    // Calculate texture UVs relative to bayer texture's dimensions and sample it from there
    return texture2D(u_bayer, mod(floor(uv / u_texelsize), vec2(1.0) / u_bayertexelsize) * u_bayertexelsize).r;
}

// Returns the dithered quantized version of colour
vec3 quantize (vec2 uv, vec3 colour, float prec)
{
    float dither = getDitherAt(uv);
    colour = clamp(floor(colour * prec + dither) / prec, vec3(0.0), vec3(1.0));
    return colour;
}

void main()
{
    float time = u_time;
    
    // Define colours for fire / flame
    vec4 fireCoreColour = vec4(1.0, 0.75, 0.3, 1.0);
    vec4 fireColour;
    
    // Define colours for smoke
    vec4 colorSmokeA = vec4(0.18, 0.13, 0.13, 0.0);
    vec4 colorSmokeB = vec4(0.38, 0.33, 0.3, 0.4);
    
    vec4 composite = vec4(0.0);
    vec4 source = texture2D( gm_BaseTexture, v_vTexcoord );
    float lumFire = source.r;
    float lumSmoke = source.b;
    
    // Rainbow fire hell yeah
    const float fireHueFreq = 0.25;
    float fireHue = time + lumFire * fireHueFreq;
    float fireSat = (1.0 - pow(lumFire, 2.0)) * 0.5;
    fireColour = vec4(hsv2rgb(vec3(fireHue, fireSat, 1.0)), 1.0);
    
    // Apply dithered downsampling to the colour
    fireColour.xyz = quantize(v_vTexcoord, fireColour.xyz, 4.0);
    
    // Step gradient from
    // https://stackoverflow.com/questions/15935117/how-to-create-multiple-stop-gradient-fragment-shader
	float stepLow = 0.0;
	float stepMidStart = 0.35;
	float stepMidEnd = 0.95;
	float stepHigh = 1.0;
	
	// Smoke
	vec4 smokeFinal = mix(colorSmokeA, colorSmokeB, lumSmoke);
	
	// Fire
	composite = mix(smokeFinal, fireColour, smoothstep(stepLow, stepMidStart, lumFire));
	composite = mix(composite, fireCoreColour, smoothstep(stepMidEnd, stepHigh, lumFire));
    
    gl_FragColor = v_vColour * composite;
    // gl_FragColor = vec4(vec3(getDitherAt(v_vTexcoord)), 1.0);
    // gl_FragColor = vec4(vec3(texture2D( gm_BaseTexture, v_vTexcoord ).r), 1.0);
}
