// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

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
