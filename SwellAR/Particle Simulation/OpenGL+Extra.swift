// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import OpenGLES

func bind(texture: GLuint, toUnit unit: Int) {
    glActiveTexture(GLenum(GL_TEXTURE0 + Int32(unit)))
    glBindTexture(GLenum(GL_TEXTURE_2D), texture)
}

func bind(attribute: GLint, to data: [GLfloat], numComponents: Int) {
    glEnableVertexAttribArray(GLenum(attribute))
    data.withUnsafeBufferPointer {
        glVertexAttribPointer(GLenum(attribute), GLint(numComponents), GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, $0.baseAddress)
    }
}

func bind(framebuffer: GLuint, to texture: GLuint? = nil) {
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
    if let texture = texture {
        glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), texture, 0)
    }
}

func createFramebuffer() -> GLuint {
    var framebuffer: GLuint = 0
    glGenFramebuffers(1, &framebuffer)
    return framebuffer
}

func deleteFramebuffer(_ framebuffer: GLuint) {
    var _framebuffer = framebuffer
    glDeleteFramebuffers(1, &_framebuffer)
}

func createTexture(width: Int, height: Int, data: [GLubyte]) -> GLuint {
    var texture: GLuint = 0
    glGenTextures(1, &texture)
    glBindTexture(GLenum(GL_TEXTURE_2D), texture)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
    data.withUnsafeBufferPointer {
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), $0.baseAddress)
    }
    glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    return texture
}

/// Creates a half-float texture.
func createTexture(width: Int, height: Int, data: [GLfloat]) -> GLuint {
    var texture: GLuint = 0
    glGenTextures(1, &texture)
    glBindTexture(GLenum(GL_TEXTURE_2D), texture)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_NEAREST)
    data.withUnsafeBufferPointer {
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_HALF_FLOAT_OES), $0.baseAddress)
    }
    glBindTexture(GLenum(GL_TEXTURE_2D), 0)
    return texture
}

func deleteTexture(_ texture: GLuint) {
    var _texture = texture
    glDeleteTextures(1, &_texture)
}

func createProgram(vertexShader: String, fragmentShader: String) throws -> GLuint {
    let vertUrl = Bundle.main.url(forResource: vertexShader, withExtension: nil, subdirectory: "Shaders")!
    let vertSource = try String(contentsOf: vertUrl)
    let vert = try ShaderCompiler.compile(source: vertSource, type: .vertexShader)
    let fragUrl = Bundle.main.url(forResource: fragmentShader, withExtension: nil, subdirectory: "Shaders")!
    let fragSource = try String(contentsOf: fragUrl)
    let frag = try ShaderCompiler.compile(source: fragSource, type: .fragmentShader)    
    let program = try ShaderCompiler.link(vertexShader: vert, fragmentShader: frag)
    glDeleteShader(vert)
    glDeleteShader(frag)
    return program
}
