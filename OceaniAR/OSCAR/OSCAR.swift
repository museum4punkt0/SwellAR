//
//  OSCAR.swift
//  Museum4
//
//  Created by Michael Schröder on 07.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation

/// Ocean Surface Current Analysis Real-time data
struct OSCAR {
    let dataset: String
    let time: Int32
    let depth: Float
    let us: [Double]
    let vs: [Double]
    let latitudes: [Double]
    let longitudes: [Double]
    
    init(data: Data) throws {
        let decoder = DataDecoder(data: data, endianness: .bigEndian)
        
        try decoder.expect("Dataset {\n")
        try decoder.skipUntil("} v;\n} ")
        dataset = try decoder.getStringUntil(";\n")
        try decoder.expect("Data:\n")
        
        let uCount = try decoder.getInt32()
        try decoder.expect(uCount)
        us = try (0 ..< uCount).map { _ in try decoder.getFloat64() }
        
        try decoder.expect(1)
        try decoder.expect(1)
        time = try decoder.getInt32()
        
        try decoder.expect(1)
        try decoder.expect(1)
        depth = try decoder.getFloat32()
        
        let latCount = try decoder.getInt32()
        try decoder.expect(latCount)
        latitudes = try (0 ..< latCount).map { _ in try decoder.getFloat64() }
        
        let lonCount = try decoder.getInt32()
        try decoder.expect(lonCount)
        longitudes = try (0 ..< lonCount).map { _ in try decoder.getFloat64() }
        
        try decoder.expect(uCount)
        try decoder.expect(uCount)
        vs = try (0 ..< uCount).map { _ in try decoder.getFloat64() }
        
        // we assume the rest of the file is as expected (same time, depth, lats and longs)
    }
    
}
