(local arena-shader-code
    "
float res = 0.003;
float threshold = 0.01;
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    vec4 up = Texel(tex, texture_coords+vec2(0,-res));
    vec4 right = Texel(tex, texture_coords+vec2(res,0));
    vec4 upright = Texel(tex, texture_coords+vec2(res,-res));
    vec4 down = Texel(tex, texture_coords+vec2(0,res));
    vec4 left = Texel(tex, texture_coords+vec2(-res,0));
    vec4 downleft = Texel(tex, texture_coords+vec2(-res,res));

    if (texturecolor.a > threshold && (up.a < threshold || right.a < threshold || upright.a < threshold)) {
      return texturecolor * 2.0;
    }

    if (texturecolor.a < threshold && (up.a > threshold || right.a > threshold || upright.a > threshold)) {
      return vec4(0.0/255.0,0.0/255.0,0.0/255.0,1);
    }

      return texturecolor * color;
}
    ")

(local arena-shader (love.graphics.newShader arena-shader-code))

arena-shader
