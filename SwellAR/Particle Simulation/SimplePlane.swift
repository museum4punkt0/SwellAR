//
//  SimplePlane.swift
//  Museum4
//
//  Created by Michael Schröder on 03.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import OpenGLES
import GLKit

/// Draws a texture, masked by another texture, onto an AR target.
final class SimplePlane {
    
    var width: Int
    var height: Int
    
    private let program: GLuint
    private let a_pos: GLint
    private let a_tex_pos: GLint
    private let u_mvp: GLint
    private let u_tex: GLint
    private let u_mask: GLint
    private let positions: [GLfloat] = [-0.5, -0.5, 0, 0.5, -0.5, 0, 0.5, 0.5, 0, -0.5, 0.5, 0]
    private let texels: [GLfloat] = [ 0, 0, 1, 0, 1, 1, 0, 1 ]
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        
        program = try! createProgram(vertexShader: "plane.vert.glsl", fragmentShader: "plane.frag.glsl")
        a_pos = glGetAttribLocation(program, "a_pos")
        a_tex_pos = glGetAttribLocation(program, "a_tex_pos")
        u_mvp = glGetUniformLocation(program, "u_mvp")
        u_tex = glGetUniformLocation(program, "u_tex")
        u_mask = glGetUniformLocation(program, "u_mask")
    }
    
    deinit {
        glDeleteProgram(program)
    }
    
    func render(texture: GLuint, mask: GLuint, on target: ARViewController.Target) {
        bind(framebuffer: target.arView.framebuffer)
        glEnable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glViewport(GLint(target.arView.viewport.origin.x), GLint(target.arView.viewport.origin.y), GLint(target.arView.viewport.size.width), GLint(target.arView.viewport.size.height))
        
        glUseProgram(program)
        bind(attribute: a_pos, to: positions, numComponents: 3)
        bind(attribute: a_tex_pos, to: texels, numComponents: 2)
        bind(texture: texture, toUnit: 0)
        bind(texture: mask, toUnit: 1)
        glUniform1i(u_tex, 0)
        glUniform1i(u_mask, 1)
        
        let scale = GLKVector3Make(Float(target.size.width), Float(target.size.height), 1)
        let mv = GLKMatrix4ScaleWithVector3(target.modelViewMatrix, scale)
        let mvp = GLKMatrix4Multiply(target.arView.projectionMatrix, mv)
        glUniformMatrix4fv(u_mvp, 1, 0, mvp.array)
        
        glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, 4)
    }
    
}
