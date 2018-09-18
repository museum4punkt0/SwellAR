precision mediump float;

attribute float a_index;

uniform sampler2D u_particles;
uniform float u_particles_res;

varying vec2 v_particle_pos;

void main() {
    vec4 color = texture2D(u_particles, vec2(fract(a_index / u_particles_res),
                                             floor(a_index / u_particles_res) / u_particles_res));
    
    // decode current particle position from the pixel's RGBA value (using half-float textures)
    v_particle_pos = vec2((color.r + color.g) / 1024.0,
                          (color.b + color.a) / 1024.0);
    
    gl_PointSize = 1.0;
    gl_Position = vec4(2.0 * v_particle_pos.x - 1.0, 1.0 - 2.0 * v_particle_pos.y, 0, 1);
}

