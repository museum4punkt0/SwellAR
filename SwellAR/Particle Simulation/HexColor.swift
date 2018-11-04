// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import Foundation

struct HexColor: Codable {
    
    let hexString: String
    let uiColor: UIColor
    
    enum Error: Swift.Error {
        case invalidEncoding(String)
    }
    
    init(_ hexString: String) throws {
        self.hexString = hexString.lowercased()
        guard let rgb = Int(hexString, radix: 16) else {
            throw Error.invalidEncoding(hexString)
        }
        let r = CGFloat((rgb & 0xff0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00ff00) >>  8) / 255.0
        let b = CGFloat((rgb & 0x0000ff) >>  0) / 255.0
        self.uiColor = UIColor(red: r, green: g, blue: b, alpha: 1)
    }
    
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        let hexString = try value.decode(String.self)
        try self.init(hexString)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hexString)
    }
    
}
