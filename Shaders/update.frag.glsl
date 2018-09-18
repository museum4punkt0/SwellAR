precision highp float;

uniform sampler2D u_particles;
uniform sampler2D u_currents;
uniform vec2 u_currents_res;
uniform vec2 u_currents_min;
uniform vec2 u_currents_max;
uniform float u_rand_seed;
uniform float u_speed_factor;
uniform float u_drop_rate;
uniform float u_drop_rate_bump;

varying vec2 v_tex_pos;

// pseudo-random generator
const vec3 rand_constants = vec3(12.9898, 78.233, 4375.85453);
float rand(const vec2 co) {
    float t = dot(rand_constants.xy, co);
    return fract(sin(t) * (rand_constants.z + t));
}

// current speed lookup; use manual bilinear filtering based on 4 adjacent pixels for smooth interpolation
vec2 lookup_current(const vec2 uv) {
    vec2 px = 1.0 / u_currents_res;
    vec2 vc = (floor(uv * u_currents_res)) * px;
    vec2 f = fract(uv * u_currents_res);
    vec2 tl = texture2D(u_currents, vc).rg;
    vec2 tr = texture2D(u_currents, vc + vec2(px.x, 0)).rg;
    vec2 bl = texture2D(u_currents, vc + vec2(0, px.y)).rg;
    vec2 br = texture2D(u_currents, vc + px).rg;
    return mix(mix(tl, tr, f.x), mix(bl, br, f.x), f.y);
}

void main() {
    vec4 color = texture2D(u_particles, v_tex_pos);
    vec2 pos = vec2((color.r + color.g) / 1024.0,
                    (color.b + color.a) / 1024.0); // decode particle position from pixel RGBA (using half-float texture)
    
    vec2 velocity = mix(u_currents_min, u_currents_max, lookup_current(pos));
    float speed_t = length(velocity) / length(u_currents_max);
    
//    // take EPSG:4236 distortion into account for calculating where the particle moved
//    float distortion = cos(radians(pos.y * 180.0 - 90.0));
    float distortion = 1.0;
    vec2 offset = vec2(velocity.x / distortion, -velocity.y) * 0.0001 * u_speed_factor;
    
    // update particle position, wrapping around the date line
    pos = fract(1.0 + pos + offset);
    
    // a random seed to use for the particle drop
    vec2 seed = (pos + v_tex_pos) * u_rand_seed;
    
    // drop rate is a chance a particle will restart at random position, to avoid degeneration
    float drop_rate = u_drop_rate + speed_t * u_drop_rate_bump;
    float drop = step(1.0 - drop_rate, rand(seed));
    
    vec2 random_pos = vec2(rand(seed + 1.3),
                           rand(seed + 2.1));
    pos = mix(pos, random_pos, drop);
    
    // encode the new particle position back into RGBA (using half-float texture)
    gl_FragColor = vec4(floor(pos.x * 1024.0), fract(pos.x * 1024.0),
                        floor(pos.y * 1024.0), fract(pos.y * 1024.0));
}
