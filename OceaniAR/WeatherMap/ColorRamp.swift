//
//  ColorRamp.swift
//  Museum4
//
//  Created by Michael Schröder on 03.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import OpenGLES
import UIKit

final class ColorRamp {
    
    let texture: GLuint
    
    init(colors: [CGColor]) {
        let data = UnsafeMutablePointer<GLubyte>.allocate(capacity: Int(256 * 1 * 4))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue).rawValue
        let context = CGContext(data: data, width: 256, height: 1, bitsPerComponent: 8, bytesPerRow: 4 * 256, space: colorSpace, bitmapInfo: bitmapInfo)!
        let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: nil)!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 256, y: 0), options: [])
        
        var _texture: GLuint = 0
        glGenTextures(1, &_texture)
        glBindTexture(GLenum(GL_TEXTURE_2D), _texture)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, 16, 16, 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), data)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        self.texture = _texture
    }
    
    deinit {
        deleteTexture(texture)
    }
    
    static let defaultColors: [CGColor] = [
        UIColor(red:0.20, green:0.53, blue:0.74, alpha:1.0).cgColor,
        UIColor(red:0.40, green:0.76, blue:0.65, alpha:1.0).cgColor,
        UIColor(red:0.67, green:0.87, blue:0.64, alpha:1.0).cgColor,
        UIColor(red:0.90, green:0.96, blue:0.60, alpha:1.0).cgColor,
        UIColor(red:1.00, green:0.88, blue:0.55, alpha:1.0).cgColor,
        UIColor(red:0.99, green:0.68, blue:0.38, alpha:1.0).cgColor,
        UIColor(red:0.96, green:0.43, blue:0.26, alpha:1.0).cgColor,
        UIColor(red:0.84, green:0.24, blue:0.31, alpha:1.0).cgColor
    ]

}
