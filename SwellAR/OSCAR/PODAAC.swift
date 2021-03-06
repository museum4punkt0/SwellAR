// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import Foundation
import Alamofire
import FeedKit

/// Physical Oceanography Distributed Active Archive Center
struct PODAAC {
    
    enum Result<T> {
        case success(T)
        case error(Error?)
    }

    static func getLatestOSCARDatasetName(completionHandler block: @escaping (Result<String>) -> Void) {
        let url = "https://podaac.jpl.nasa.gov/ws/search/granule/"
        let parameters = [
            "datasetId": "PODAAC-OSCAR-03D01",
            "startTime": ISO8601DateFormatter().string(from: Date()),
            "startIndex": "1",
            "itemsPerPage": "1",
            "sortBy": "timeDesc",
            "format": "atom"
        ]
        Alamofire.request(url, parameters: parameters).responseData { response in
            if let data = response.result.value {
                let parser = FeedParser(data: data)
                let result = parser.parse()
                if let dataset = result.atomFeed?.entries?.first?.title {
                    block(.success(dataset))
                } else {
                    block(.error(nil))
                }
            } else {
                block(.error(response.error))
            }
        }
    }
    
    static func downloadOSCAR(dataset: String, bounds: Bounds, completionHandler block: @escaping (Result<OSCAR>) -> Void) {
        let url = "https://podaac-opendap.jpl.nasa.gov:443/opendap/allData/oscar/preview/L4/oscar_third_deg/\(dataset).gz.dods?u[0:1:0][0:1:0][\(bounds.latMinIndex):1:\(bounds.latMaxIndex)][\(bounds.lonMinIndex):1:\(bounds.lonMaxIndex)],v[0:1:0][0:1:0][\(bounds.latMinIndex):1:\(bounds.latMaxIndex)][\(bounds.lonMinIndex):1:\(bounds.lonMaxIndex)]"
        Alamofire.request(url).responseData { response in
            if let data = response.result.value {
                do {
                    let oscar = try OSCAR(data: data)
                    block(.success(oscar))
                } catch let error {
                    block(.error(error))
                }
            } else {
                block(.error(response.error))
            }
        }
    }
    
    /// Indexes into OSCAR lat/lon arrays.
    ///
    /// Latitude range: 0 = 80N, 420 = -80N, grid size = 1/3.
    /// To convert from latitudes to indexes use the formula `240-round(3x)`.
    ///
    /// Longitude range: 0 = 20E, 1200 = 420E, grid size = 1/3, data repeats in overlap region
    /// To convert from longitudes to indexes use the formula `round(3x)-60`.
    ///
    struct Bounds: Codable {
        let latMinIndex: Int
        let latMaxIndex: Int
        let lonMinIndex: Int
        let lonMaxIndex: Int
    }
    
}
