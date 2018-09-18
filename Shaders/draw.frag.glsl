precision mediump float;

uniform sampler2D u_currents;
uniform vec2 u_currents_min;
uniform vec2 u_currents_max;
uniform float u_color_factor;
uniform sampler2D u_color_ramp;

varying vec2 v_particle_pos;

void main() {
    vec4 current = texture2D(u_currents, v_particle_pos);
    if (current.a == 0.0) discard;
    vec2 velocity = mix(u_currents_min, u_currents_max, current.rg);
    
    float speed_t = (length(velocity) / length(u_currents_max)) * u_color_factor;
    
    // color ramp is encoded in a 16x16 texture
    vec2 ramp_pos = vec2(fract(16.0 * speed_t),
                         floor(16.0 * speed_t) / 16.0);
    
    gl_FragColor = texture2D(u_color_ramp, ramp_pos);
}

