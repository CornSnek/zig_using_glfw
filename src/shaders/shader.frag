#version 460 core
layout(location = 1) uniform float time;
out vec4 frag_color;
uniform float pi = 3.1415926535;
void main()
{
  frag_color = vec4(( cos(time) + 1 ) / 2, ( cos(time + pi * 2 / 3) + 1 ) / 2, ( cos(time + pi * 4 / 3) + 1 ) / 2, 1.0);
}