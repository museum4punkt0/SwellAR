//
//  TouchIcon.swift
//  OceaniAR
//
//  Created by Michael Schröder on 23.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation
import GLKit
import OpenGLES

class TouchIcon {
    
    var href: String?
    
    /// Relative to the width of the target
    var x: CGFloat = 0.5
    
    /// Relative to the height of the target
    var y: CGFloat = 0.5
    
    /// Relative to the width of the target
    var radius: CGFloat = 0.1
    
    private let texture: GLKTextureInfo
    private let effect: GLKBaseEffect
    private let positions: [GLfloat] = [-0.5, -0.5, 0, 0.5, -0.5, 0, 0.5, 0.5, 0, -0.5, 0.5, 0]
    private let texels: [GLfloat] = [ 0, 0, 1, 0, 1, 1, 0, 1 ]
    
    init(image: CGImage) {
        texture = try! GLKTextureLoader.texture(with: image, options: [GLKTextureLoaderOriginBottomLeft: true])
        effect = GLKBaseEffect()
        effect.texture2d0.name = texture.name
    }
    
    deinit {
        deleteTexture(texture.name)
    }
    
    func render(on target: Target, in arView: ARView) {
        glDisable(GLenum(GL_DEPTH_TEST))
        
        let dx = -target.size.width/2 + x*target.size.width
        let dy = target.size.height - target.size.height/2 - y*target.size.height
        let mv = GLKMatrix4Translate(target.modelViewMatrix, Float(dx), Float(dy), 0)
        
        let s = target.size.width * radius
        effect.transform.modelviewMatrix = GLKMatrix4Scale(mv, Float(s), Float(s), Float(s))
        
        effect.transform.projectionMatrix = arView.projectionMatrix
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
    
    func hitTest(_ point: CGPoint, in target: Target) -> Bool {
        let x1 = point.x / target.size.width
        let y1 = (target.size.height - point.y) / target.size.height
        return x - radius < x1 && x1 < x + radius
            && y - radius < y1 && y1 < y + radius
    }
    
}
