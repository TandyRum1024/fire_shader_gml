//
// OH GOD
// IM BURNING
attribute vec3 in_Position;                  // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_pixelsize; // 텍스쳐 공간 (0...1)에서 차지하는 한 픽셀의 너비 & 높이

uniform vec2 u_texturesize; // 텍스쳐의 사이즈. 게임메이커에서 넘겨주세요!

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
    
    // 한 픽셀의 크기 구하기 -- 텍스쳐의 크기로 나누어 비율을 구합니다
    v_pixelsize = (vec2(1.0) / u_texturesize);
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// 사나이 울리는 불타는 쉐이더 -- 불 이펙트 단계
// 여기서 나온 결과를 다른 쉐이더에서 이쁘게 지지고 볶고 하시면 됩니다.
// 사용하실때 불의 강도(??)가 R 채널에 저장된다는거 참고하세요!
// zik@2019
// -------------------------
// 참고 : https://web.archive.org/web/20160418004150/http://freespace.virgin.net/hugo.elias/models/m_fire.htm

// 이 Define을 주석 처리하면 쉐이더 내에서 노이즈를 생성합니다.
// 대신 미리 만들어진 텍스쳐를 쓰는것보다 느리겠죠?
// #define USE_EXTERNAL_NOISE

// 불이 바람에 일렁이는 효과 사용
#define USE_WINDMAP

// 연기를 B 채널에 저장?
#define RENDER_SMOKE

#define M_PI 3.14159265358979323846

varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_pixelsize;

uniform sampler2D u_coolingmap; // 불 노이즈 텍스쳐. 이쁜 노이즈를 넘겨주시면 될겁니다
uniform sampler2D u_source; // 소스 텍스쳐 -- 이 텍스쳐로 불 이펙트를 계산합니다.
uniform float u_time; // 시간

uniform float u_scrollspeed;// = 4.0;
uniform float u_windstrength;// = 1.5;
uniform float u_windspeed;// = 1.5;

// Fractional Brownian motion 노이즈 -- Inigo Quilez 제작
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

float intensity (sampler2D src, vec2 uv)
{
    vec4 tex = texture2D(src, uv);
    return (tex.r + tex.b) * 0.5;
}

// 픽셀 주위의 평균값을 가져오는 함수
float neighbor2D (sampler2D src, vec2 uv)
{
    float pl = texture2D(src, uv - vec2(v_pixelsize.x, 0.0)).r;
    float pr = texture2D(src, uv + vec2(v_pixelsize.x, 0.0)).r;
    float pt = texture2D(src, uv - vec2(0.0, v_pixelsize.y)).r;
    float pb = texture2D(src, uv + vec2(0.0, v_pixelsize.y)).r;
    
    return (pl + pr + pt + pb) * 0.25;
}

float neighborSmoke (sampler2D src, vec2 uv)
{
    float pl = intensity(src, uv - vec2(v_pixelsize.x, 0.0));
    float pr = intensity(src, uv + vec2(v_pixelsize.x, 0.0));
    float pt = intensity(src, uv - vec2(0.0, v_pixelsize.y));
    float pb = intensity(src, uv + vec2(0.0, v_pixelsize.y));
    
    return (pl + pr + pt + pb) * 0.5;
}

// 바람을 구하는 함수
vec2 windmap2D (vec2 uv, float time, float strength)
{
    float windx = noise(uv * 5.0 + vec2(time)) + (sin(uv.y * 16.0 + 21.0 + uv.x * 21.0 + time) + sin(time + uv.x * 32.0 + 0.42)) * strength;
    float windy = noise(uv * 5.0 + vec2(time)) + (cos(uv.x * 16.0 + 21.0 + uv.y * 2.0 + time) + sin(uv.y * 32.0 + time + 0.24 + cos(uv.x * 2.0 + time) * 1.0) * 0.5) * strength;
    
    return vec2((windx - 0.5), (windy - 0.5)) * 0.001;
}

void main()
{
    vec4 final = vec4(vec3(0.0), 1.0);
    float timeOff = u_time * 0.05;
    
    /*
        불!!!!!
    */
    vec2 uvFire = v_vTexcoord + vec2(0.0, v_pixelsize.y * u_scrollspeed);
    
    // 평균값 가져오기
    #ifdef USE_WINDMAP
        vec2 flowmap = windmap2D(v_vTexcoord, timeOff * u_windspeed, u_windstrength);
    #else
        vec2 flowmap = vec2(0.0);
    #endif
    
    float lumFire = neighbor2D(u_source, uvFire + flowmap); // fire
    
    // 냉각맵 (텍스쳐) 값 가져오기
    float fireY = (v_vTexcoord.y + v_pixelsize.y * u_scrollspeed * u_time); // fract로 offy 가 0..1 범위에 있게 만들어요
    
    #ifdef USE_EXTERNAL_NOISE
        float coolmapRaw = texture2D(u_coolingmap, vec2(v_vTexcoord.x, fract(fireY))).r;
        // 냉각맵 감마 조정
        float coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
        coolmap *= coolmap;
        coolmap *= 0.95;
    #else
        float coolmapRaw = fbm((vec2(v_vTexcoord.x, fireY) + flowmap) * 40.0);
        // 냉각맵 감마 조정
        float coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
        coolmap *= 0.25;
    #endif
    
    // 적용
    float fireFinal = max(lumFire - coolmap, 0.0);
    final.r = fireFinal;
    
    /*
        연기!!!!!
    */
    #ifdef RENDER_SMOKE
        const float smokeMultiplier = 1.5;
        vec2 uvSmoke = uvFire + vec2(0.0, v_pixelsize.y * smokeMultiplier);
        
        #ifdef USE_WINDMAP
            flowmap += windmap2D(v_vTexcoord, timeOff * u_windspeed, u_windstrength * 0.01 * smokeMultiplier);
        #else
            flowmap = vec2(0.0);
        #endif
        
        float lumSmoke = neighborSmoke(u_source, uvSmoke + flowmap);
        float smokeY = (v_vTexcoord.y + smokeMultiplier + v_pixelsize.y * smokeMultiplier * u_scrollspeed * u_time);
        
        #ifdef USE_EXTERNAL_NOISE
            coolmapRaw = texture2D(u_coolingmap, vec2(v_vTexcoord.x, fract(smokeY)) * 0.5).r;
            // 냉각맵 감마 조정
            coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
            coolmap *= coolmap;
            coolmap *= 0.75;
        #else
            coolmapRaw = fbm((vec2(v_vTexcoord.x, smokeY) + flowmap) * 15.0);
            // 냉각맵 감마 조정
            coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
            coolmap *= 0.25;
        #endif
        
        float smokeFinal = max(lumSmoke - coolmap, 0.0);
        final.b = smokeFinal;
    #endif

    gl_FragColor = final;
}

