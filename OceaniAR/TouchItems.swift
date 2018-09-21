//
//  TouchItems.swift
//  OceaniAR
//
//  Created by Michael Schröder on 21.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation
import UIKit

struct TouchItems: Codable {
    let width: Int
    let height: Int
    let items: [Item]
    
    struct Item: Codable {
        let href: String
        let x: Int
        let y: Int
        let radius: Int
        let circle: UIBezierPath
        
        enum CodingKeys: String, CodingKey {
            case href
            case x
            case y
            case radius
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            href = try values.decode(String.self, forKey: .href)
            x = try values.decode(Int.self, forKey: .x)
            y = try values.decode(Int.self, forKey: .y)
            radius = try values.decode(Int.self, forKey: .radius)
            circle = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: CGFloat(radius), startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        }
    }
    
    func convert(_ point: CGPoint, from size: CGSize) -> CGPoint {
        return CGPoint(
            x: (CGFloat(width) * point.x) / size.width,
            y: (CGFloat(height) * (size.height - point.y)) / size.height
        )
    }
    
    static var `default`: TouchItems = {
        let url = Bundle.main.url(forResource: "touch_items", withExtension: "json", subdirectory: "Config")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(TouchItems.self, from: data)
    }()
}




