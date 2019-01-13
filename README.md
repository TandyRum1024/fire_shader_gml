<h1 align="center">게임메이커 스튜디오 예제:<br>:fire:절차적으로 생성된 화염 효과:fire:</h1>

<h3 align="center">GLSL(쉐이더)를 이용한 :fire:화끈하게 불살라버리는:fire: 예제입니다.<br/><a href="https://web.archive.org/web/20160418004150/http://freespace.virgin.net/hugo.elias/models/m_fire.htm"><b>Hugo Elias</b>의 화염 효과</a> 그리고 <a href="https://www.youtube.com/watch?v=X0kjv0MozuY"><b>The Coding Train</b>에서 만든 비디오</a>를 베이스로 하였습니다.
</h3>

<img align="center" src="imgs/DEMO_BANNER.gif" alt="렌지짱 미트스핀" title="슈퍼 미트 보이!!!!!!">

이 예제는요..
====
- GLSL 을 기반으로 한 절차적으로 생성된 화염 효과
- 2개의 쉐이더를 사용합니다; 불을 계산하는것과 그걸 토대로 효과를 주는 쉐이더
- 여러가지 설정 가능한 변수들: 바람 세기, 바람 속도 등등..
- 막 연기도 나요

뭐요, 게임메이커요?
====
***당연하죠!*** GLSL (= 픽셀 단위로 이미지를 수정 가능한 환경) 을 지원하는 모든 것에서도 돌아갈 수 있다는걸 증명하기 위해서이기도 하고, 결과적으로 게임메이커는 재밌잖아요 :D

사용법
====
게임메이커 스튜디오를 사용하고 계시면 `LIT_AF.gmx` 폴더 속 프로젝트를 import 하시면 됩니다. 

프로젝트에 여러가지 쉐이더가 있지만, 결과적으로 당신의 프로젝트에 사용할 쉐이더는 다음과 같습니다:
- `shd_fire` 는 불 효과를 계산하는 역할을 합니다.
- `shd_fire_effect` 와 `shd_fire_effect_cartoon` 는 `shd_fire` 에서 나온 결과를 *더 불같이* 만들어주는 역할을 합니다.
- 나머지 쉐이더들은 그냥 눈요깃거리를 위한 쉐이더입니다.

어떻게 제작되었나요
====
원본 [의사 코드](https://web.archive.org/web/20160418004150/http://freespace.virgin.net/hugo.elias/models/m_fire.htm)는 다음과 같습니다 :
```
loop forever

  loop y  from 1 to (ysize-2)                   ;Loop through all pixels on the screen, except
    loop x  from 1 to (xsize-2)                 ;the ones at the very edge.

      n1 = read pixel from buffer1(x+1, y)      ;Read the 4 neighbouring pixels
      n2 = read pixel from buffer1(x-1, y)
      n3 = read pixel from buffer1(x, y+1)
      n4 = read pixel from buffer1(x, y-1)

      c  = read pixel from CoolingMap(x, y)     ;Read a pixel from the cooling map

      p = ((n1+n2+n3+n4) / 4)                   ;The average of the 4 neighbours
      p = p-c                                   ;minus c

      if p<0 then p=0                           ;Don't let the fire cool below zero

      write pixel of value p to buffer2(x,y-1)  ;write this pixel to the other buffer
                                                ;notice that it is one pixel higher.

    end x loop
  end yloop

  copy buffer2 to the screen                    ;Display the next frame
  copy buffer2 to buffer1                       ;Update buffer1
  scroll CoolingMap up one pixel

end of loop
```

그리고 저는 다음과 같이 효과를 구현했습니다 :

![demonstration 1](imgs/DEMO_WORK1.gif)

*우선, 원본 이미지 (왼쪽)을 완전히 하얗게* ***불 텍스쳐*** *에 드로우 합니다. (오른쪽).*

**(매 프레임마다 불 텍스쳐의 내용물을 지우는건 하지 않습니다. 다음 프레임에 써야 하거든요. [아래 참고])**

![demonstration 2](imgs/DEMO_WORK2.gif)

*그러고나서 불 텍스쳐를 첫 번째, 불을 계산하는 쉐이더 (이 예제에서는 `shd_fire`입니다)를 이용해 불과 연기를 계산하고 결과를 불 텍스쳐에 다시 넣습니다. (그러고나선 다음 프레임에서 이 텍스쳐를 다시 쉐이더에 넣고 계산하고.. 를 반복합니다.)*

*(왼쪽의 불 텍스쳐를 쉐이더에 적용하여서 오른쪽의 결과를 얻었습니다. 실제로는 저 오른쪽의 텍스쳐에 쉐이더를 적용하고 그 결과를 다시 오른쪽의 텍스쳐에 넣는것을 반복하죠.)*

쉐이더에서는 다음과 같은 일을 합니다;
- 현재 픽셀과 이웃하는 픽셀(왼쪽, 오른쪽, 위쪽, 아래쪽 픽셀)의 R(빨강) 채널의 평균을 구해서 변수에 저장합니다. (이 값을 `lumFire`로 부르겠습니다.)<br>
(참고로 현재 픽셀 대신 아랫 픽셀의 값을 구해서 텍스쳐를 "위로 스크롤" 합니다.)
```
// 주어진 픽셀과 이웃하는 픽셀의 평균값을 가져오는 함수 (R채널)
float neighbor2D (sampler2D src, vec2 uv)
{
    float pl = texture2D(src, uv - vec2(v_pixelsize.x, 0.0)).r;
    float pr = texture2D(src, uv + vec2(v_pixelsize.x, 0.0)).r;
    float pt = texture2D(src, uv - vec2(0.0, v_pixelsize.y)).r;
    float pb = texture2D(src, uv + vec2(0.0, v_pixelsize.y)).r;
    
    return (pl + pr + pt + pb) * 0.25;
}

// v_pixelsize 는 텍스쳐 공간 내에서의 한 픽셀의 사이즈입니다.
// 한 픽셀 아래의 값을 구함으로써 텍스쳐를 위로 스크롤합니다.
float lumFire = neighbor2D(u_source, v_vTexcoord + vec2(0.0, v_pixelsize.y));
```
- 그리고 주어진 노이즈 텍스쳐 (냉각 맵, uniform을 이용해 직접 설정하거나 쉐이더 내에서 생성된 노이즈를 사용합니다.)의 R채널 / 밝기를 구해서 변수에 저장합니다. (이 값을 `coolmap` 으로 부르겠습니다.)<br>
(그리고 `lumFire`와 같이 텍스쳐를 위로 스크롤 합니다. 그리고 `coolmap`의 값을 살짝 기호에 맞게 조정해주세요.)
```
    // 냉각맵 (텍스쳐) 값 가져오기
    // 한 픽셀 아래의 uv 값; 이를 이용해 텍스쳐를 위로 스크롤합니다.
    float fireY = (v_vTexcoord.y + v_pixelsize.y * u_scrollspeed * u_time);
    
    #ifdef USE_EXTERNAL_NOISE // <- 사용자 지정 냉각맵 사용 여부
        // u_coolingmap = 사용자 지정 냉각 맵 텍스쳐
        float coolmapRaw = texture2D(u_coolingmap, vec2(v_vTexcoord.x, fract(fireY))).r; // fract로 fireY 가 0..1 범위에 있게 만들어요
        // 냉각맵 조정
        float coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
        coolmap *= coolmap;
        coolmap *= 0.95;
    #else // 쉐이더에서 생성된 노이즈를 냉각맵으로 사용
        // fbm = 노이즈 함수
        float coolmapRaw = fbm((vec2(v_vTexcoord.x, fireY) + flowmap) * 40.0);
        // 냉각맵 조정
        float coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
        coolmap *= 0.25;
    #endif
```
- 그리고 방금 얻은 `coolmap`의 값을 `lumFire` 의 값에서 뺀 값을 얻습니다. 그리고 그 값을 0보다 작지 않게 제한해줍니다.<br>
```
// r 채널에 결과값 저장
float fireFinal = max(lumFire - coolmap, 0.0);
final.r = fireFinal;
```
- 그리고 위 코드처럼 텍스쳐의 R 채널에 결과값을 저장합니다.
- 마찬가지로 연기도 같은 방법으로 계산합니다. (중간에 `coolmap`의 값을 살짝 조절해 불보다는 더 잘 퍼지게 하고 더 역동적이게 만들어 줍니다.) 그리고 그 결과값을 텍스쳐의 B 채널에 저장합니다.
- 추가로, 위에서 냉각 맵과 불의 세기의 값을 구할때 좌표에다가 약간의 변동을 주어 바람을 구현하였습니다.<br>
```
// flowmap 은 바람을 구현하기 위한 오프셋.
float lumFire = neighbor2D(u_source, uvFire + flowmap);
float coolmapRaw = texture2D(u_coolingmap, vec2(v_vTexcoord.x, fract(fireY)) + flowmap).r;
```

![demonstration 3](imgs/DEMO_WORK3.gif)

*좌측 상단 : 불 / R 채널<br>좌측 하단 : 연기 / B 채널<br>우측 : 좌측의 값들을 토대로 렌더링 된 불 효과*

*그런 다음, 그 결과를 불 효과를 주는 역할을 하는 쉐이더(이 예제에서는 `shd_fire_effect`)를 적용시킵니다. 이전과 같이 R 채널과 B 채널을 읽고 그 값을 토대로 불 효과를 제작합니다.*
```
vec4 composite = vec4(0.0);
vec4 source = texture2D( gm_BaseTexture, v_vTexcoord );

float lumFire = source.r; // R채널 - 불
float lumSmoke = source.b; // B채널 - 연기

// 스텝 그라디언트
// https://stackoverflow.com/questions/15935117/how-to-create-multiple-stop-gradient-fragment-shader
float stepLow = 0.0;
float stepMidStart = 0.35;
float stepMidEnd = 0.95;
float stepHigh = 1.0;

// 연기
vec4 smokeFinal = mix(colorSmokeA, colorSmokeB, lumSmoke);

// 불
composite = mix(smokeFinal, colorAmber, smoothstep(stepLow, stepMidStart, lumFire));
composite = mix(composite, colorMid, smoothstep(stepMidStart, stepMidEnd, lumFire));
composite = mix(composite, colorCore, smoothstep(stepMidEnd, stepHigh, lumFire));

gl_FragColor = v_vColour * composite;
```

![demonstration 4](imgs/DEMO_WORK4.gif)

*그러고 나서 그 위에 원본 이미지를 드로우 하면 끝!*

# 추가 자료
[Hugo Elias의 원본 문서](https://web.archive.org/web/20160418004150/http://freespace.virgin.net/hugo.elias/models/m_fire.htm)

[The Coding Train에서 제작한 위 효과를 Processing으로 구현하는 비디오](https://www.youtube.com/watch?v=X0kjv0MozuY)

[Hugo Elias의 유체 역학을 토대로 한 불 효과를 구현하는 또 다른 방법](https://web.archive.org/web/20160418004147/http://freespace.virgin.net/hugo.elias/models/m_ffire.htm)

["Warp feedback" -- 왜곡 시뮬레이션. 이를 이용해 위에서 저술한 효과를 한 층 더 향상시킬 수 있습니다.](https://web.archive.org/web/20160418004149/http://freespace.virgin.net/hugo.elias/graphics/x_warp.htm)

[Inigo Quilez의 Fractional Brownian motion 노이즈](https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83) 가 쉐이더 내부 노이즈 생성에 사용되었습니다. [(원본 쉐이더)](https://www.shadertoy.com/view/MdX3Rr)

["불타면서 이미지가 나타나는/사라지는 효과"](https://cafe.naver.com/playgm/98574) 를 토대로 제작된 쉐이더가 이 예제에 사용되었습니다.

["스텝 그라디언트" 코드](https://stackoverflow.com/questions/15935117/how-to-create-multiple-stop-gradient-fragment-shader) 가 불 효과 쉐이더에 사용되었습니다.

# 사진들
![OH](imgs/DEMO_HD.gif)
![OH](imgs/DEMO_PIXEL.gif)
![OH](imgs/AVOCADO.gif)
![OH](imgs/MEAT.gif)
