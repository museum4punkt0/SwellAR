//
//  OceanCurrents+OSCAR.swift
//  Museum4
//
//  Created by Michael Schröder on 17.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation
import CoreGraphics

struct OceanCurrentsMetadata: Codable {
    let dataset: String
    let time: Int  // days since 1992-10-05
    let width: Float
    let height: Float
    let latMin: Float
    let latMax: Float
    let lonMin: Float
    let lonMax: Float
    let uMin: Float
    let uMax: Float
    let vMin: Float
    let vMax: Float
}

extension OSCAR {
    func createImage() -> (CGImage, OceanCurrentsMetadata)? {
        let width = longitudes.count
        let height = latitudes.count
        guard width > 0, height > 0 else {
            return nil
        }

        guard
            let uMin = us.minimum(),
            let uMax = us.maximum(),
            let vMin = vs.minimum(),
            let vMax = vs.maximum()
            else {
                return nil
        }

        let metadata = OceanCurrentsMetadata(
            dataset: dataset,
            time: Int(time),
            width: Float(width),
            height: Float(height),
            latMin: Float(latitudes.first!),
            latMax: Float(latitudes.last!),
            lonMin: Float(longitudes.first!),
            lonMax: Float(longitudes.last!),
            uMin: Float(uMin),
            uMax: Float(uMax),
            vMin: Float(vMin),
            vMax: Float(vMax)
        )

        var pixels: [UInt8] = Array(repeating: 0, count: width * height * 4)
        for k in 0 ..< width * height {
            let i = k * 4
            let u = us[k]
            let v = vs[k]
            if u.isNaN || v.isNaN {
                pixels[i + 0] = 0
                pixels[i + 1] = 0
                pixels[i + 2] = 0
                pixels[i + 3] = 0
            } else {
                pixels[i + 0] = UInt8(floor(255 * (u - uMin) / (uMax - uMin)))
                pixels[i + 1] = UInt8(floor(255 * (v - vMin) / (vMax - vMin)))
                pixels[i + 2] = 0
                pixels[i + 3] = 255
            }
        }

        guard
            let providerRef = CGDataProvider(data: Data(bytes: pixels) as CFData),
            let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: providerRef, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            else {
                return nil
        }

        return (image, metadata)
    }
}

