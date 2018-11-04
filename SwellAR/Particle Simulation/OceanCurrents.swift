// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import Foundation
import OpenGLES
import GLKit

/// The OSCAR current data as a texture. Never changes.
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
