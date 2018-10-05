precision mediump float;

uniform sampler2D u_tex;
uniform sampler2D u_mask;
varying vec2 v_tex_pos;

void main() {
    vec4 color = texture2D(u_tex, v_tex_pos);
    vec4 mask = texture2D(u_mask, v_tex_pos);
    gl_FragColor = color * mask.r;
}
