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
        let icon: String
        let href: String
        let x: Int
        let y: Int
        let radius: Int
    }
    
    static var `default`: TouchItems = {
        let url = Bundle.main.url(forResource: "touch_items", withExtension: "json", subdirectory: "Config")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(TouchItems.self, from: data)
    }()
}




