//
//  PODAAC.swift
//  Museum4
//
//  Created by Michael Schröder on 10.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation
import Alamofire
import FeedKit

/// Physical Oceanography Distributed Active Archive Center
struct PODAAC {
    
    static func getLatestOSCARDatasetName(completionHandler block: @escaping (String?, Error?) -> Void) {
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
                let dataset = result.atomFeed?.entries?.first?.title
                block(dataset, nil)
            } else {
                block(nil, response.error)
            }
        }
    }
    
    static func downloadOSCAR(dataset: String, latitude: (minIndex: Int, maxIndex: Int), longitude: (minIndex: Int, maxIndex: Int), completionHandler block: @escaping (OSCAR?, Error?) -> Void) {
        let url = "https://podaac-opendap.jpl.nasa.gov:443/opendap/allData/oscar/preview/L4/oscar_third_deg/\(dataset).gz.dods?u[0:1:0][0:1:0][\(latitude.minIndex):1:\(latitude.maxIndex)][\(longitude.minIndex):1:\(longitude.maxIndex)],v[0:1:0][0:1:0][\(latitude.minIndex):1:\(latitude.maxIndex)][\(longitude.minIndex):1:\(longitude.maxIndex)]"
        Alamofire.request(url).responseData { response in
            if let data = response.result.value {
                do {
                    let oscar = try OSCAR(data: data)
                    block(oscar, nil)
                } catch let error {
                    block(nil, error)
                }
            } else {
                block(nil, response.error)
            }
        }
    }
    
}
