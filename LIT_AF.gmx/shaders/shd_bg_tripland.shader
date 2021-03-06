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
// Simple passthrough fragment shader
//
#define M_PI 3.14159265358979323846

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float u_time;
uniform vec2 u_texelsize;
uniform vec2 u_bayertexelsize;
uniform sampler2D u_bayer;

// Fetches dithering texture
float getDitherAt (vec2 uv)
{
    // Calculate texture UVs relative to bayer texture's dimensions and sample it from there
    return texture2D(u_bayer, mod(floor(uv / u_texelsize), vec2(1.0) / u_bayertexelsize) * u_bayertexelsize).r;
}

// Original HSV to RBG routine from
// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 hsv2rgb (vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float muncher (vec2 uv)
{
	uv = (uv - 0.5);
// 	uv.y /= (u_texelsize.y / u_texelsize.x);
 
	vec2 b = uv * 256.0 + 256.0;
	float c = 0.0;
	float p = 0.0;
 
 
	for(float i=16.0; i>=1.0; i-=1.0)
	{
		p = pow(2.0, i);
 		
		if(abs(min(ceil(b.x - p), 1.0) - min(ceil(b.y - p), 1.0)) == 0.0)
		{
			c += p;
		}
 
		if(p < b.x)
		{
			b.x -= p;
		}
 
		if(p < b.y)
		{
			b.y -= p;
		}
	}
 
	c = mod(c / 128.0, 1.0);
	return c;
}

vec3 sampleScene (vec2 uv, float time)
{
	// apply downscale
	uv = floor(uv / u_texelsize) * u_texelsize;
	
    const float pi2 = 2.0 * M_PI;
    float zoom = sin(time * 0.5) * 0.25 + 1.0;
    float rot = time * (pi2 / 20.0);
	uv.y /= (u_texelsize.y / u_texelsize.x);
    uv -= 0.5;
    uv *= mat2(cos(rot), -sin(rot), sin(rot), cos(rot)); // rotate
	uv *= zoom; // scale
	uv.x += fract(time * 0.1 + sin(time * (pi2 / 4.0) + 1.25) * 0.1); // translate
	uv.y += fract(time * 0.5 + cos(time * (pi2 / 10.0) + 0.75) * 0.02); // translate
	uv += 0.5;
	
	float munchpattern = muncher(uv);
	vec3 c = vec3(munchpattern, sin(munchpattern * M_PI * 2.0 + time * 0.5) * 0.5 + 0.5, clamp(tan(munchpattern * M_PI * 0.5 + time * 0.5), 0.0, 1.0)) * 0.25;
	
    return c;
}

void main()
{
    vec3 before = sampleScene(v_vTexcoord, u_time - 0.25);
    vec3 after = sampleScene(v_vTexcoord, u_time);
    
    // apply dither motion blur
    vec3 final = mix(before, after, floor(getDitherAt(v_vTexcoord) + 0.5));
    
    gl_FragColor = vec4(final, 1.0); // v_vColour * texture2D( gm_BaseTexture, v_vTexcoord );
}

