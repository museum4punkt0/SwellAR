// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import Foundation

class DataDecoder {
    
    enum Error: Swift.Error {
        case outOfRange(Int)
        case invalidStringEncoding
        case unexpectedData
    }
    
    enum Endianness {
        case littleEndian
        case bigEndian
    }
    
    private let data: Data
    private(set) var offset: Int = 0
    let endianness: Endianness
    
    var remaining: Int {
        return data.count - offset
    }
    
    init(data: Data, endianness: Endianness) {
        self.data = data
        self.endianness = endianness
    }
    
    func skip(_ n: Int) throws {
        guard offset + n <= data.count else {
            throw Error.outOfRange(offset + n)
        }
        offset += n
    }
    
    func skipUntil(_ expected: Data) throws {
        guard let range = data.range(of: expected, options: [], in: offset ..< data.count) else {
            throw Error.outOfRange(data.count)
        }
        offset = range.upperBound
    }
    
    func skipUntil(_ expected: String, encoding: String.Encoding = .ascii) throws {
        guard let x = expected.data(using: encoding) else {
            throw Error.invalidStringEncoding
        }
        try skipUntil(x)
    }
    
    func moveTo(_ offset: Int) throws {
        try checkRange(offset)
        self.offset = offset
    }
    
    func get(_ n: Int) throws -> Data {
        try checkRange(offset + n)
        let x = data[offset ..< offset+n]
        offset += n
        return x
    }
    
    func getInt32() throws -> Int32 {
        try checkRange(offset + 4)
        let x0: Int32 = data[offset ..< offset+4].withUnsafeBytes({$0.pointee})
        let x: Int32
        switch endianness {
        case .littleEndian:
            x = Int32(littleEndian: x0)
        case .bigEndian:
            x = Int32(bigEndian: x0)
        }
        offset += 4
        return x
    }
    
    func getFloat32() throws -> Float32 {
        try checkRange(offset + 4)
        let x0: UInt32 = data[offset ..< offset+4].withUnsafeBytes({$0.pointee})
        let x1: UInt32
        switch endianness {
        case .littleEndian:
            x1 = UInt32(littleEndian: x0)
        case .bigEndian:
            x1 = UInt32(bigEndian: x0)
        }
        let x = Float32(bitPattern: x1)
        offset += 4
        return x
    }
    
    func getFloat64() throws -> Float64 {
        try checkRange(offset + 8)
        let x0: UInt64 = data[offset ..< offset+8].withUnsafeBytes({$0.pointee})
        let x1: UInt64
        switch endianness {
        case .littleEndian:
            x1 = UInt64(littleEndian: x0)
        case .bigEndian:
            x1 = UInt64(bigEndian: x0)
        }
        let x = Float64(bitPattern: x1)
        offset += 8
        return x
    }
    
    func getString(_ n: Int, encoding: String.Encoding = .ascii) throws -> String {
        try checkRange(offset + n)
        guard let x = String(data: data[offset ..< offset+n], encoding: encoding) else {
            throw Error.invalidStringEncoding
        }
        offset += n
        return x
    }
    
    func getStringUntil(_ expected: String, encoding: String.Encoding = .ascii) throws -> String {
        guard let x = expected.data(using: encoding) else {
            throw Error.invalidStringEncoding
        }
        guard let range = data.range(of: x, options: [], in: offset ..< data.count) else {
            throw Error.outOfRange(data.count)
        }
        let str = try getString(range.lowerBound - offset)
        offset = range.upperBound
        return str
    }
    
    func expect(_ expected: Data) throws {
        try checkRange(offset + expected.count)
        guard data[offset ..< offset+expected.count] == expected else {
            throw Error.unexpectedData
        }
        offset += expected.count
    }
    
    func expect(_ expected: Int32) throws {
        var x1: Int32
        switch endianness {
        case .littleEndian:
            x1 = expected.littleEndian
        case .bigEndian:
            x1 = expected.bigEndian
        }
        let x = Data(bytes: &x1, count: MemoryLayout.size(ofValue: x1))
        try expect(x)
    }
    
    func expect(_ expected: String, encoding: String.Encoding = .ascii) throws {
        guard let x = expected.data(using: encoding) else {
            throw Error.invalidStringEncoding
        }
        try expect(x)
    }
    
    private func checkRange(_ n: Int) throws {
        guard n < data.count else {
            throw Error.outOfRange(n)
        }
    }
    
}
