//
//  Array+Double.swift
//  Museum4
//
//  Created by Michael Schröder on 09.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation

extension Array where Element == Double {
    
    /// Returns the minimum element in the array, eliminating NaN when possible.
    func minimum() -> Double? {
        guard self.count > 0 else {
            return nil
        }
        var y = Double.nan
        for x in self {
            y = Double.minimum(x, y)
        }
        return y
    }
    
    /// Returns the maximum element in the array, eliminating NaN when possible.
    func maximum() -> Double? {
        guard self.count > 0 else {
            return nil
        }
        var y = Double.nan
        for x in self {
            y = Double.maximum(x, y)
        }
        return y
    }
    
}
