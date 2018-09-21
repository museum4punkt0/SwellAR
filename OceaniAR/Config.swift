//
//  Config.swift
//  OceaniAR
//
//  Created by Michael Schröder on 18.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation

struct Config: Codable {
    let minLatIndex: Int
    let maxLatIndex: Int
    let minLonIndex: Int
    let maxLonIndex: Int
    let mapWidth: Int
    let mapHeight: Int
    let fadeOpacity: Float
    let colorFactor: Float
    let speedFactor: Float
    let dropRate: Float
    let dropRateBump: Float
    let resolution: Int
    let colors: [HexColor]
    
    static var `default`: Config = {
        let configUrl = Bundle.main.url(forResource: "config", withExtension: "json", subdirectory: "Config")!
        let configData = try! Data(contentsOf: configUrl)
        return try! JSONDecoder().decode(Config.self, from: configData)
    }()
}

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
