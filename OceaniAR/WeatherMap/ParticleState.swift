//
//  ParticleState.swift
//  Museum4
//
//  Created by Michael Schröder on 03.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import OpenGLES

final class ParticleState {
    
    /// How fast the particles move
    var speedFactor: Float = 20
    
    /// How often the particles move to a random place
    var dropRate: Float = 0.003
    
    /// Drop rate increase relative to individual particle speed
    var dropRateBump: Float = 0.01
    
    var texture: GLuint {
        return texture0
    }

    var resolution: Int = 256 {
        didSet {
            resize()
        }
    }

    var numParticles: Int {
        return resolution * resolution
    }
    
    var oceanCurrents: OceanCurrents
    
    private(set) var indexBuffer: [GLfloat] = []

    private var texture0: GLuint = 0
    private var texture1: GLuint = 0
    
    private let framebuffer: GLuint
    private let program: GLuint
    private let a_pos: GLint
    private let u_particles: GLint
    private let u_currents: GLint
    private let u_currents_res: GLint
    private let u_currents_min: GLint
    private let u_currents_max: GLint
    private let u_rand_seed: GLint
    private let u_speed_factor: GLint
    private let u_drop_rate: GLint
    private let u_drop_rate_bump: GLint
    private let quadBuffer: [GLfloat] = [0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1]
    
    init(oceanCurrents: OceanCurrents) {
        self.oceanCurrents = oceanCurrents
        
        framebuffer = createFramebuffer()
        program = try! createProgram(vertexShader: "quad.vert.glsl", fragmentShader: "update.frag.glsl")
        a_pos = glGetAttribLocation(program, "a_pos")
        u_particles = glGetUniformLocation(program, "u_particles")
        u_currents = glGetUniformLocation(program, "u_currents")
        u_currents_res = glGetUniformLocation(program, "u_currents_res")
        u_currents_min = glGetUniformLocation(program, "u_currents_min")
        u_currents_max = glGetUniformLocation(program, "u_currents_max")
        u_rand_seed = glGetUniformLocation(program, "u_rand_seed")
        u_speed_factor = glGetUniformLocation(program, "u_speed_factor")
        u_drop_rate = glGetUniformLocation(program, "u_drop_rate")
        u_drop_rate_bump = glGetUniformLocation(program, "u_drop_rate_bump")
        
        resize()
    }
    
    private func resize() {
        deleteTexture(texture0)
        deleteTexture(texture1)
        indexBuffer = (0 ..< self.numParticles).map { GLfloat($0) }
        // TODO: start with random particles
        let randomState = (0 ..< self.numParticles * 4).map { _ in Float(0) }
        texture0 = createTexture(width: resolution, height: resolution, data: randomState)
        texture1 = createTexture(width: resolution, height: resolution, data: randomState)
    }
    
    deinit {
        deleteTexture(texture0)
        deleteTexture(texture1)
        deleteFramebuffer(framebuffer)
        glDeleteProgram(program)
    }
    
    func update() {
        glDisable(GLenum(GL_DEPTH_TEST))
        glDisable(GLenum(GL_STENCIL_TEST))
        glDisable(GLenum(GL_BLEND))
        
        bind(framebuffer: framebuffer, to: texture1)
        glViewport(0, 0, GLsizei(resolution), GLsizei(resolution))
        
        glUseProgram(program)
        bind(attribute: a_pos, to: quadBuffer, numComponents: 2)
        bind(texture: oceanCurrents.texture, toUnit: 0)
        bind(texture: texture0, toUnit: 1)
        glUniform1i(u_currents, 0)
        glUniform1i(u_particles, 1)
        glUniform1f(u_rand_seed, Float(Float(arc4random()) / Float(UINT32_MAX)))
        glUniform2f(u_currents_res, oceanCurrents.metadata.width, oceanCurrents.metadata.height);
        glUniform2f(u_currents_min, oceanCurrents.metadata.uMin, oceanCurrents.metadata.vMin);
        glUniform2f(u_currents_max, oceanCurrents.metadata.uMax, oceanCurrents.metadata.vMax);
        glUniform1f(u_speed_factor, speedFactor);
        glUniform1f(u_drop_rate, dropRate);
        glUniform1f(u_drop_rate_bump, dropRateBump);        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        swap(&texture0, &texture1)
    }
    
}
