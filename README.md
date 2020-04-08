<h1 align="center">Fire effect example<br>:fire:for GameMaker: Studio:fire:</h1>

<h3 align="center">A brief example of using GLSL based fire effect heavily inspired & based from<br/><a href="https://web.archive.org/web/20160418004150/http://freespace.virgin.net/hugo.elias/models/m_fire.htm"><b>Hugo Elias'</b> article about fire effect</a> and <a href="https://www.youtube.com/watch?v=X0kjv0MozuY">Video tutorial about it from <b>The Coding Train</b></a>
</h3>

![GATO](imgs/DEMO_PIXEL_2.gif)
![MEAT](imgs/DEMO_BANNER.gif)

Short list of features
====
- GLSL based fire rendering
- 2-pass Shader effect
- Adjustable shader settings like wind strength, usage of external noise texture
- There's also smoke comming out of it

Wait, Gamemaker?
====
Yeah! You're right, I used GameMaker for this example to show you that you can apply this effect to everything that supports GLSL shader.

How to use
====
If you're using GameMaker Studio 1, You can directly import the project in the folder `LIT_AF.gmx`.

There's few shaders that might make you tad bit confused, But no worries!<br>Here's the list of shaders that you want to export / copy & use it in your own projects:
- `shd_fire` is the one that calculates the fire
- `shd_fire_effect` and `shd_fire_effect_cartoon` makes the output from `shd_fire` more *Fire-ish*
- everything else is miscellaneous shaders.

How it works
====
The [original pseudocode](https://web.archive.org/web/20160418004150/http://freespace.virgin.net/hugo.elias/models/m_fire.htm) goes like this :
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

And here's how I achieved the effect :

![demonstration 1](imgs/DEMO_WORK1.gif)

*First, We draw the source image (left), full-white into our Fire buffer (right).*

**(We don't want to clear the Fire buffer, As we need the data from previous frame to calculate the next frame!)**

![demonstration 2](imgs/DEMO_WORK2.gif)

*Then, We Feed the Fire buffer into first shader(`shd_fire` in this example) and in that shader, We read it's red and blue channel, calculate fire & smoke from it and write it into red and blue channel of Fire buffer itself.(so we can use this on next frame)*

*After feeding the Fire buffer on the left, Now our Fire buffer looks like the one on the right.*

Here's what happens in the first shader;
- On each pixel, we get the average of red channel from it's four neighbor (top, left, bottom, right) -- We'll call this value `lumFire`<br>
(Also, We "scroll" the texture by getting the Intensity of pixel below the current one.)<br>
```
// Function to get the average of the neighbor's red channel
float neighbor2D (sampler2D src, vec2 uv)
{
    float pl = texture2D(src, uv - vec2(v_pixelsize.x, 0.0)).r;
    float pr = texture2D(src, uv + vec2(v_pixelsize.x, 0.0)).r;
    float pt = texture2D(src, uv - vec2(0.0, v_pixelsize.y)).r;
    float pb = texture2D(src, uv + vec2(0.0, v_pixelsize.y)).r;
    
    return (pl + pr + pt + pb) * 0.25;
}

// v_pixelsize is the size of pixel in texture space.
// We scroll the texture by sampling the pixel below.
float lumFire = neighbor2D(u_source, v_vTexcoord + vec2(0.0, v_pixelsize.y));
```
- We also get the brightness / red channel of our noise texture (cooling map) either fed in by sampler or generated in shader. -- We'll call this value `coolmap`<br>
(We "scroll" the cooling map as same way as Inteinsity, And The cooling map has to be adjusted a little bit for desired effect.)
```
    // UV's y-component for sampling the pixel below & scrolling
    float fireY = (v_vTexcoord.y + v_pixelsize.y * u_scrollspeed * u_time);
    
    #ifdef USE_EXTERNAL_NOISE // <- Whether to use user defined noise texture for cooling map
        // u_coolingmap = user defined cooling map
        float coolmapRaw = texture2D(u_coolingmap, vec2(v_vTexcoord.x, fract(fireY))).r; // use fract() to keep our UVs in [0..1] space
        // Adjust cooling map
        float coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
        coolmap *= coolmap;
        coolmap *= 0.95;
    #else // <- Use shader-generated noise
        // fbm = Noise function
        float coolmapRaw = fbm((vec2(v_vTexcoord.x, fireY) + flowmap) * 40.0);
        // Adjust cooling map
        float coolmap = smoothstep(0.0, 1.0, coolmapRaw * coolmapRaw);
        coolmap *= 0.25;
    #endif
```
- And we substract `coolmap`, From value of `lumFire` we've got earlier. Also we limit the result so that it doesn't go below zero.. And we save that into red channel of the texture.<br>
```
// Subtract, Clamp it and save the result into red channel.
float fireFinal = max(lumFire - coolmap, 0.0);
final.r = fireFinal;
```
- Same goes for Smoke, But we adjust the cooling map's value a little bit so that it spreads more & goes "dynamic". and we store that value into blue channel.
- I've offseted the sampling location of Intensity and Cooling map by few pixels so it emulates the effect of wind.<br>
```
// flowmap is the offset value to emulate the wind
float lumFire = neighbor2D(u_source, uvFire + flowmap);
float coolmapRaw = texture2D(u_coolingmap, vec2(v_vTexcoord.x, fract(fireY)) + flowmap).r;
```

![demonstration 3](imgs/DEMO_WORK3.gif)

*Top left : Fire data / red channel<br>Bottom left : Smoke data / Blue channel<br>Right : Composite result generated from the values left*

*And now we feed that result into yet another shader(`shd_fire_effect` in this example) and in that shader, We read it's red and blue channel (again) and use that for creating Fire-ish effect.*
```
vec4 composite = vec4(0.0);
vec4 source = texture2D( gm_BaseTexture, v_vTexcoord );

float lumFire = source.r; // red channel - fire
float lumSmoke = source.b; // blue channel - smoke

// Step gradient from
// https://stackoverflow.com/questions/15935117/how-to-create-multiple-stop-gradient-fragment-shader
float stepLow = 0.0;
float stepMidStart = 0.35;
float stepMidEnd = 0.95;
float stepHigh = 1.0;

// Smoke
vec4 smokeFinal = mix(colorSmokeA, colorSmokeB, lumSmoke);

// Fire
composite = mix(smokeFinal, colorAmber, smoothstep(stepLow, stepMidStart, lumFire));
composite = mix(composite, colorMid, smoothstep(stepMidStart, stepMidEnd, lumFire));
composite = mix(composite, colorCore, smoothstep(stepMidEnd, stepHigh, lumFire));

gl_FragColor = v_vColour * composite;
```

![demonstration 4](imgs/DEMO_WORK4.gif)

*Now we can just plop the source image on it and there she goes, It's done & good to go.*

# Further readings
[Original technique by Hugo Elias](https://web.archive.org/web/20160418004150/http://freespace.virgin.net/hugo.elias/models/m_fire.htm)

[Video of implementing above in Processing by The Coding Train](https://www.youtube.com/watch?v=X0kjv0MozuY)

[Fluid simulation based Fire by Hugo Elias](https://web.archive.org/web/20160418004147/http://freespace.virgin.net/hugo.elias/models/m_ffire.htm)

["Warp feedback" which you could infuse with this to improve the visuals by Hugo Elias](https://web.archive.org/web/20160418004149/http://freespace.virgin.net/hugo.elias/graphics/x_warp.htm)

[Fractional Brownian motion noise by Inigo Quilez](https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83) was used for internal noise generation [(Original shader)](https://www.shadertoy.com/view/MdX3Rr)

["Disintegration effect"](https://cafe.naver.com/playgm/98574) was used for second demo

["Step gradient" code snipset](https://stackoverflow.com/questions/15935117/how-to-create-multiple-stop-gradient-fragment-shader) was used for fire effect shader

# Gallery
![OH](imgs/DEMO_HD.gif)
![OH](imgs/DEMO_PIXEL.gif)
![OH](imgs/AVOCADO.gif)
![OH](imgs/MEAT.gif)