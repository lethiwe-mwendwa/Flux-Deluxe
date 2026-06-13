#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D tex0;
uniform vec2 resolution;
uniform float pixelSize;

void main() {

  vec2 uv = gl_FragCoord.xy / resolution;

  vec2 pixelUV = floor(uv * resolution / pixelSize) * pixelSize / resolution;

  gl_FragColor = texture2D(tex0, pixelUV);
}