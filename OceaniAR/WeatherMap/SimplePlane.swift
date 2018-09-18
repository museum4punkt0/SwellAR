//
//  SimplePlane.swift
//  Museum4
//
//  Created by Michael Schröder on 03.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import OpenGLES
import GLKit

final class SimplePlane {
    
    var width: Int
    var height: Int
    
    private let program: GLuint
    private let a_pos: GLint
    private let a_tex_pos: GLint
    private let u_mvp: GLint
    private let u_tex: GLint
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
    }
    
    deinit {
        glDeleteProgram(program)
    }
    
    func render(texture: GLuint, targetSize: CGSize, targetModelView: GLKMatrix4, arView: ARView) {
        bind(framebuffer: arView.framebuffer)
        glEnable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glViewport(GLint(arView.viewport.origin.x), GLint(arView.viewport.origin.y), GLint(arView.viewport.size.width), GLint(arView.viewport.size.height))
        
        glUseProgram(program)
        bind(attribute: a_pos, to: positions, numComponents: 3)
        bind(attribute: a_tex_pos, to: texels, numComponents: 2)
        bind(texture: texture, toUnit: 0)
        glUniform1i(u_tex, 0)
        
        let scale = GLKVector3Make(Float(targetSize.width), Float(targetSize.height), 1)
        let mv = GLKMatrix4ScaleWithVector3(targetModelView, scale)
        let mvp = GLKMatrix4Multiply(arView.projectionMatrix, mv)
        glUniformMatrix4fv(u_mvp, 1, 0, mvp.array)
        
        glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, 4)
    }
    
}
