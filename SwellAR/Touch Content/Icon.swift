// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import Foundation
import GLKit
import OpenGLES

class Icon {
    
    // MARK: - Icon Cache
    
    private static var cache: [String: Icon] = [:]
    
    static func named(_ name: String) -> Icon? {
        if let icon = cache[name] {
            return icon
        } else {
            guard let image = UIImage(named: name)?.cgImage else {
                return nil
            }
            let icon = Icon(image: image)
            cache[name] = icon
            return icon
        }
    }
    
    // MARK: -
    
    private let texture: GLKTextureInfo
    private let effect: GLKBaseEffect
    private let positions: [GLfloat] = [-0.5, -0.5, 0, 0.5, -0.5, 0, 0.5, 0.5, 0, -0.5, 0.5, 0]
    private let texels: [GLfloat] = [ 0, 0, 1, 0, 1, 1, 0, 1 ]
    
    init?(image: CGImage) {
        guard let texture = try? GLKTextureLoader.texture(with: image, options: [GLKTextureLoaderOriginBottomLeft: true]) else {
            return nil
        }
        self.texture = texture
        effect = GLKBaseEffect()
        effect.texture2d0.name = texture.name
    }
    
    deinit {
        deleteTexture(texture.name)
    }
    
    /// Coordinates are normalized relative to the target.
    func render(on target: ARViewController.Target, at point: CGPoint, radius: CGFloat) {
        glDisable(GLenum(GL_DEPTH_TEST))
        
        let dx = -target.size.width/2 + (point.x * target.size.width)
        let dy = target.size.height - target.size.height/2 - (point.y * target.size.height)
        let mv = GLKMatrix4Translate(target.modelViewMatrix, Float(dx), Float(dy), 0)
        
        let s = target.size.width * radius
        effect.transform.modelviewMatrix = GLKMatrix4Scale(mv, Float(s), Float(s), Float(s))
        
        effect.transform.projectionMatrix = target.arView.projectionMatrix
        effect.prepareToDraw()
        
        glEnableVertexAttribArray(GLenum(GLKVertexAttrib.position.rawValue))
        glEnableVertexAttribArray(GLenum(GLKVertexAttrib.texCoord0.rawValue))
        positions.withUnsafeBufferPointer {
            glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, $0.baseAddress)
        }
        texels.withUnsafeBufferPointer {
            glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, $0.baseAddress)
        }
        glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, 4)
    }
    
}
