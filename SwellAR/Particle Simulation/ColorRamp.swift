// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import OpenGLES

/// A color ramp texture, to provide a gradient of colors for rising ocean current velocities.
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
   
}
