//
//  ParticleScreen.swift
//  Museum4
//
//  Created by Michael Schröder on 03.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import OpenGLES

final class ParticleScreen {
    
    /// How fast the particle trails fade on each frame
    var fadeOpacity: Float = 0.996
    
    var colorFactor: Float = 10.0
    
    var texture: GLuint {
        return texture0
    }
    
    let width: Int
    let height: Int
    let particleState: ParticleState
    var colorRamp: ColorRamp
    
    private var texture0: GLuint
    private var texture1: GLuint
    private let framebuffer: GLuint
    
    private let screenProgram: GLuint
    private let a_pos: GLint
    private let u_screen: GLint
    private let u_opacity: GLint
    private let quadBuffer: [GLfloat] = [0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1]
    
    private let particleProgram: GLuint
    private let a_index: GLint
    private let u_particles: GLint
    private let u_particles_res: GLint
    private let u_currents: GLint
    private let u_currents_min: GLint
    private let u_currents_max: GLint
    private let u_color_factor: GLint
    private let u_color_ramp: GLint
    
    init(width: Int, height: Int, particleState: ParticleState, colorRamp: ColorRamp) {
        self.width = width
        self.height = height
        self.particleState = particleState
        self.colorRamp = colorRamp
        
        let emptyPixels: [GLubyte] = Array(repeating: 0, count: width * height * 4)
        texture0 = createTexture(width: width, height: height, data: emptyPixels)
        texture1 = createTexture(width: width, height: height, data: emptyPixels)
        framebuffer = createFramebuffer()
        
        screenProgram = try! createProgram(vertexShader: "quad.vert.glsl", fragmentShader: "screen.frag.glsl")
        a_pos = glGetAttribLocation(screenProgram, "a_pos")
        u_screen = glGetUniformLocation(screenProgram, "u_screen")
        u_opacity = glGetUniformLocation(screenProgram, "u_opacity")
        
        particleProgram = try! createProgram(vertexShader: "draw.vert.glsl", fragmentShader: "draw.frag.glsl")
        a_index = glGetAttribLocation(particleProgram, "a_index")
        u_particles = glGetUniformLocation(particleProgram, "u_particles")
        u_particles_res = glGetUniformLocation(particleProgram, "u_particles_res")
        u_currents = glGetUniformLocation(particleProgram, "u_currents")
        u_currents_min = glGetUniformLocation(particleProgram, "u_currents_min")
        u_currents_max = glGetUniformLocation(particleProgram, "u_currents_max")
        u_color_ramp = glGetUniformLocation(particleProgram, "u_color_ramp")
        u_color_factor = glGetUniformLocation(particleProgram, "u_color_factor")
    }
    
    deinit {
        deleteTexture(texture0)
        deleteTexture(texture1)
        deleteFramebuffer(framebuffer)
        glDeleteProgram(screenProgram)
        glDeleteProgram(particleProgram)
    }
    
    func draw() {
        glDisable(GLenum(GL_DEPTH_TEST))
        glDisable(GLenum(GL_STENCIL_TEST))
        glDisable(GLenum(GL_BLEND))
        
        bind(framebuffer: framebuffer, to: texture1)
        glViewport(0, 0, GLsizei(width), GLsizei(height))
        
        glUseProgram(screenProgram)
        bind(attribute: a_pos, to: quadBuffer, numComponents: 2)
        bind(texture: texture0, toUnit: 0)
        glUniform1i(u_screen, 0)
        glUniform1f(u_opacity, fadeOpacity)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        
        glUseProgram(particleProgram)
        bind(attribute: a_index, to: particleState.indexBuffer, numComponents: 1)
        bind(texture: particleState.oceanCurrents.texture, toUnit: 0)
        bind(texture: particleState.texture, toUnit: 1)
        bind(texture: colorRamp.texture, toUnit: 2)
        glUniform1i(u_currents, 0)
        glUniform1i(u_particles, 1)
        glUniform1i(u_color_ramp, 2)
        glUniform1f(u_particles_res, GLfloat(particleState.resolution))
        glUniform2f(u_currents_min, particleState.oceanCurrents.metadata.uMin, particleState.oceanCurrents.metadata.vMin)
        glUniform2f(u_currents_max, particleState.oceanCurrents.metadata.uMax, particleState.oceanCurrents.metadata.vMax)
        glUniform1f(u_color_factor, colorFactor)
        glDrawArrays(GLenum(GL_POINTS), 0, GLsizei(particleState.numParticles))
        
        swap(&texture0, &texture1)
    }
    
}
