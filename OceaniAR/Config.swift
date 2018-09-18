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
    
    static var `default`: Config = {
        let configUrl = Bundle.main.url(forResource: "config", withExtension: "json", subdirectory: "Config")!
        let configData = try! Data(contentsOf: configUrl)
        return try! JSONDecoder().decode(Config.self, from: configData)
    }()
}
