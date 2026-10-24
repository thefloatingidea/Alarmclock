#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Full-scene mood pass: dusk grade, burn grade, ruin grade, heat haze, vignette.
// Driven by two numbers (uProgress, uDusk) so one destruction value styles the whole scene.

uniform vec2 uSize;      // scene size (same units as FlutterFragCoord)
uniform float uProgress; // 0 = healthy, 1 = fully destroyed
uniform float uDusk;     // 0 = day, 1 = night
uniform float uTime;     // seconds
uniform float uHaze;     // 1 = heat haze on (High quality), 0 = off
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;

  // burn rises early and fades into the ruin grade at the end
  float burn = smoothstep(0.05, 0.55, uProgress) * (1.0 - smoothstep(0.80, 1.0, uProgress));
  float ruin = smoothstep(0.78, 1.0, uProgress);

  // heat haze: small wobble of the sampling position
  float amt = uHaze * burn * 0.0035;
  uv += amt * vec2(sin(uv.y * 70.0 + uTime * 3.0), cos(uv.x * 55.0 + uTime * 2.3));
  uv = clamp(uv, vec2(0.0), vec2(1.0));

  vec4 src = texture(uTexture, uv);
  vec3 c = src.rgb;

  // dusk
  c = mix(c, c * vec3(0.64, 0.52, 0.78), uDusk);

  // burning: warm orange cast
  vec3 fire = c * vec3(1.0, 0.62, 0.48) + vec3(0.05, 0.0, 0.0);
  c = mix(c, fire, burn);

  // ruins: desaturate and cool down
  float g = dot(c, vec3(0.299, 0.587, 0.114));
  vec3 ruined = mix(c, vec3(g), 0.5) * vec3(0.74, 0.78, 0.94);
  c = mix(c, ruined, ruin);

  // vignette grows with destruction and night
  vec2 d = uv - 0.5;
  float v = 1.0 - dot(d, d) * (0.5 + 0.9 * max(burn, ruin) + 0.6 * uDusk);
  c *= clamp(v, 0.0, 1.0);

  fragColor = vec4(c * src.a, src.a);
}
