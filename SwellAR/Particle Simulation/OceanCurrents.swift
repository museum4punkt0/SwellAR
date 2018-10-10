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
    
    init(contentsOf url: URL) throws {
        let metadataData = try Data(contentsOf: url.appendingPathComponent("metadata.json"))
        self.metadata = try JSONDecoder().decode(OceanCurrentsMetadata.self, from: metadataData)
        let textureUrl = url.appendingPathComponent("texture.png")
        let textureInfo = try GLKTextureLoader.texture(withContentsOf: textureUrl, options: nil)
        self.texture = textureInfo.name
    }

    deinit {
        deleteTexture(texture)
    }
    
}
