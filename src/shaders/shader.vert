#version 460 core
layout (location = 0) in vec3 v;
layout (location = 1) uniform float time;
void main()
{
  gl_Position = vec4(v.x * cos(time), v.y * cos(time), v.z, 1.0);
}