//
//  ShaderCompiler.swift
//  OceaniAR
//
//  Created by Michael Schröder on 18.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import OpenGLES

struct ShaderCompiler {
    
    enum ShaderType {
        case fragmentShader
        case vertexShader
    }
    
    enum Error: Swift.Error {
        case compileError(String)
        case linkError(String)
    }
    
    static func compile(source: String, type: ShaderType) throws -> GLuint {
        let shader: GLuint
        switch type {
        case .vertexShader:
            shader = glCreateShader(GLenum(GL_VERTEX_SHADER))
        case .fragmentShader:
            shader = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
        }
        var sourceUTF8 = (source as NSString).utf8String
        glShaderSource(shader, 1, &sourceUTF8, nil)
        glCompileShader(shader)
        var status: GLint = 0
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        if status == 0 {
            var log: String?
            var logLength: GLint = 0
            glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if logLength > 0 {
                let logBuffer = UnsafeMutablePointer<GLchar>.allocate(capacity: Int(logLength))
                glGetShaderInfoLog(shader, logLength, &logLength, logBuffer)
                log = String(validatingUTF8: logBuffer)
                logBuffer.deallocate()
            }
            glDeleteShader(shader)
            throw Error.compileError(log ?? "unknown error")
        }
        return shader
    }
    
    static func link(vertexShader: GLuint, fragmentShader: GLuint, attributes: [GLint: String] = [:]) throws -> GLuint {
        let program = glCreateProgram()
        glAttachShader(program, vertexShader)
        glAttachShader(program, fragmentShader)
        for (index,name) in attributes {
            glBindAttribLocation(program, GLenum(index), name)
        }
        glLinkProgram(program)
        
        var status: GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &status)
        if status == 0 {
            var log: String?
            var logLength: GLint = 0
            glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if logLength > 0 {
                let logBuffer = UnsafeMutablePointer<GLchar>.allocate(capacity: Int(logLength))
                glGetProgramInfoLog(program, logLength, &logLength, logBuffer)
                log = String(validatingUTF8: logBuffer)
                logBuffer.deallocate()
            }
            glDeleteProgram(program)
            throw Error.linkError(log ?? "unknown error")
        }
        
        glDetachShader(program, vertexShader)
        glDetachShader(program, fragmentShader)
        
        return program
    }
    
}
