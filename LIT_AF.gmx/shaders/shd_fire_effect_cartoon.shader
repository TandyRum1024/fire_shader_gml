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
// Fire effect : Cel shaded
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec4 u_colourmid;
uniform vec4 u_colourcore;
uniform vec4 u_coloursmoke;

float round (float val)
{
    return floor(val + 0.5);
}

void main()
{
    vec2 distort = vec2(sin(v_vTexcoord.y * 42.0 + 42.42) + cos(v_vTexcoord.x * 22.0 + 8.2),
                        cos(v_vTexcoord.x * 42.0 + 42.42) + sin(v_vTexcoord.y * 22.0 + 8.2)) * 0.001;
    
    vec4 composite = vec4(0.0);
    vec4 source = texture2D( gm_BaseTexture, v_vTexcoord );
    vec4 sourceDistort = texture2D( gm_BaseTexture, v_vTexcoord + distort );
    
    float lumFire = source.r;
    float lumFireDistort = sourceDistort.r;
    float lumSmoke = source.b;
    
    // Gradient (smoke)
    float interpSmoke = lumSmoke;
    composite = mix(composite, u_coloursmoke, smoothstep(0.0, 1.5, interpSmoke * interpSmoke));
    
    // Gradient (fire)
    float stepCore = 0.80;
    float stepMidEnd = 0.79;
    float stepMid = 0.41;
    float stepThreshold = 0.4;
    
    composite = mix(composite, u_colourmid, smoothstep(stepThreshold, stepMid, lumFire)); // antialias
    composite = mix(composite, u_colourmid, round(smoothstep(stepMid, stepMidEnd, lumFire)));
    composite = mix(composite, u_colourcore, round(smoothstep(stepMidEnd, stepCore, lumFireDistort)));
    
    gl_FragColor = v_vColour * composite;
}

