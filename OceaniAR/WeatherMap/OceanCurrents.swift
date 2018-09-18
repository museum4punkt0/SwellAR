//
//  OceanCurrents.swift
//  Museum4
//
//  Created by Michael Schröder on 09.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation
import OpenGLES
import GLKit

final class OceanCurrents {
    
    let texture: GLuint
    let metadata: OceanCurrentsMetadata
    
    static func load(contentsOf url: URL, sharegroup: EAGLSharegroup, completionHandler block: @escaping (OceanCurrents?, Error?) -> Void) {
        var metadata: OceanCurrentsMetadata?
        do {
            let jsonData = try Data(contentsOf: url.appendingPathComponent("metadata.json"))
            metadata = try JSONDecoder().decode(OceanCurrentsMetadata.self, from: jsonData)
        } catch let error {
            block(nil, error)
        }
        
        GLKTextureLoader(sharegroup: sharegroup).texture(withContentsOf: url.appendingPathComponent("texture.png"), options: nil, queue: DispatchQueue(label: "OceanCurrents.load")) { textureInfo, error in
            if let textureInfo = textureInfo {
                let oceanCurrents = OceanCurrents(texture: textureInfo.name, metadata: metadata!)
                block(oceanCurrents, nil)
            } else {
                block(nil, error)
            }
        }
    }
    
    private init(texture: GLuint, metadata: OceanCurrentsMetadata) {
        self.texture = texture
        self.metadata = metadata
    }
    
    deinit {
        deleteTexture(texture)
    }
    
}
