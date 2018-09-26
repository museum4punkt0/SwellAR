//
//  GLKMatrix+Array.swift
//  OceaniAR
//
//  Created by Michael Schröder on 18.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import GLKit

extension GLKMatrix4 {
    var array: [Float] {
        return (0..<16).map { i in
            self[i]
        }
    }
}
