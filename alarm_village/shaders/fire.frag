#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Procedural flame for one fire point. Drawn on a small quad; transparent outside the flame.

uniform vec2 uSize;       // quad size
uniform float uTime;      // seconds
uniform float uSeed;      // per-fire offset so flames do not move in sync
uniform float uIntensity; // 0..1, flame height and brightness

out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * vnoise(p);
    p *= 2.0;
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  float y = clamp(1.0 - uv.y, 0.0, 1.0); // 0 = base of flame, 1 = top of quad
  float x = uv.x - 0.5;

  float n = fbm(vec2(uv.x * 3.0 + uSeed, y * 2.5 - uTime * 1.8));
  float height = clamp(uIntensity, 0.0, 1.0) * (0.62 + 0.38 * n);

  // flame narrows toward the tip and sways with the noise
  float width = mix(0.46, 0.04, pow(y, 0.7));
  float sway = (n - 0.5) * 0.5 * y;
  float shape = 1.0 - smoothstep(0.0, max(width, 0.001), abs(x + sway));
  float body = pow(clamp(1.0 - y / max(height, 0.001), 0.0, 1.0), 0.6);
  float f = shape * body;

  // colour ramp: deep red, red-orange, orange, hot yellow
  vec3 col = vec3(0.45, 0.05, 0.02);
  col = mix(col, vec3(0.93, 0.27, 0.11), smoothstep(0.05, 0.30, f));
  col = mix(col, vec3(1.00, 0.60, 0.18), smoothstep(0.25, 0.55, f));
  col = mix(col, vec3(1.00, 0.92, 0.55), smoothstep(0.55, 0.85, f));

  float a = smoothstep(0.04, 0.22, f);
  fragColor = vec4(col * a, a); // premultiplied alpha
}
