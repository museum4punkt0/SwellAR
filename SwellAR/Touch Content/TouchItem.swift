//
//  TouchItem.swift
//  OceaniAR
//
//  Created by Michael Schröder on 21.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation
import UIKit

class TouchItem {
    
    // normalized coordinates
    let x: Float
    let y: Float
    let radius: Float
    
    let image: String
    let href: String
    
    private(set) var icon: Icon?
    
    private init(mapWidth: Int, mapHeight: Int, x: Int, y: Int, radius: Int, image: String, href: String) {
        self.x = Float(x) / Float(mapWidth)
        self.y = Float(y) / Float(mapHeight)
        self.radius = Float(radius) / Float(mapWidth)
        self.image = image
        self.href = href
    }

    func render(on target: ARViewController.Target) {
        if icon == nil {
            icon = Icon.named(image)
        }
        icon?.render(on: target, at: CGPoint(x: CGFloat(x), y: CGFloat(y)), radius: CGFloat(radius))
    }
    
    func hitTest(_ point: CGPoint, in target: ARViewController.Target) -> Bool {
        let x1 = Float(point.x / target.size.width)
        let y1 = Float((target.size.height - point.y) / target.size.height)
        return x - radius < x1 && x1 < x + radius
            && y - radius < y1 && y1 < y + radius
    }
    
}

extension TouchItem {
    
    private struct TouchItemsJSON: Codable {
        let width: Int
        let height: Int
        let items: [Item]
        
        struct Item: Codable {
            let x: Int
            let y: Int
            let radius: Int
            let image: String
            let href: String
        }
    }

    static func touchItems(contentsOf url: URL) throws -> [TouchItem] {
        var items: [TouchItem] = []
        let data = try Data(contentsOf: url)
        let touchItems = try JSONDecoder().decode(TouchItemsJSON.self, from: data)
        for item in touchItems.items {
            items.append(TouchItem(
                mapWidth: touchItems.width,
                mapHeight: touchItems.height,
                x: item.x,
                y: item.y,
                radius: item.radius,
                image: item.image,
                href: item.href
            ))
        }
        return items
    }
    
}


