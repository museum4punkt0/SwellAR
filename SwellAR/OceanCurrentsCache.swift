//
//  OceanCurrentsCache.swift
//  Museum4
//
//  Created by Michael Schröder on 11.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation
import UIKit

/// Manages the OSCAR dataset for a particular `Map`.
///
/// Starting from the default dataset provided by the app, an `OceanCurrentsCache` ensures that the cached dataset is always the latest version available.
final class OceanCurrentsCache {
    
    static let didChange = Notification.Name("OceanCurrentsCacheDidChangeNotification")
    
    struct Index: Codable {
        let latest: String
        let bounds: PODAAC.Bounds
    }
    
    private(set) var index: Index
    private(set) var latestDataset: URL
    
    let mapName: String
    let cacheDirectory: URL
    
    init(mapName: String) {
        self.mapName = mapName
        cacheDirectory = Map.localUrl(for: mapName).appendingPathComponent("OceanCurrents", isDirectory: true)
        let indexUrl = cacheDirectory.appendingPathComponent("index.json")
        if let indexData = try? Data(contentsOf: indexUrl),
            let index = try? JSONDecoder().decode(Index.self, from: indexData) {
            self.index = index
        } else {
            _ = try? FileManager.default.removeItem(at: cacheDirectory)
            try! FileManager.default.createDirectory(at: cacheDirectory.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            let bundleDir = Map.bundleUrl(for: mapName).appendingPathComponent("OceanCurrents", isDirectory: true)
            try! FileManager.default.copyItem(at: bundleDir, to: cacheDirectory)
            let indexData = try! Data(contentsOf: indexUrl)
            self.index = try! JSONDecoder().decode(Index.self, from: indexData)
        }
        latestDataset = cacheDirectory.appendingPathComponent(index.latest, isDirectory: true)
    }
    
    func update() {
        PODAAC.getLatestOSCARDatasetName { result1 in
            switch result1 {
            case let .error(error):
                print("\(self.mapName): error getting latest OSCAR dataset name: \(error as Error?)")
            case let .success(name):
                if self.index.latest == name {
                    return
                }
                PODAAC.downloadOSCAR(dataset: name, bounds: self.index.bounds) { result2 in
                    switch result2 {
                    case let .error(error):
                        print("\(self.mapName): error downloading OSCAR data: \(error as Error?)")
                    case let .success(oscar):
                        self.addDataset(oscar: oscar)
                    }
                }
            }
        }
    }
    
    private func addDataset(oscar: OSCAR) {
        guard
            let (image, metadata) = oscar.createImage(),
            let pngData = UIImage(cgImage: image).pngData()
        else {
            print("\(mapName): error creating image from OSCAR dataset \(oscar.dataset)")
            return
        }
        let datasetUrl = cacheDirectory.appendingPathComponent(oscar.dataset, isDirectory: true)
        let textureUrl = datasetUrl.appendingPathComponent("texture.png")
        let metadataUrl = datasetUrl.appendingPathComponent("metadata.json")
        do {
            try FileManager.default.createDirectory(at: datasetUrl, withIntermediateDirectories: true, attributes: nil)
            try pngData.write(to: textureUrl)
            let jsonData = try JSONEncoder().encode(metadata)
            try jsonData.write(to: metadataUrl)
        } catch let error {
            print("\(mapName): error caching image and/or metadata for OSCAR dataset \(oscar.dataset): \(error)")
            return
        }
        latestDataset = datasetUrl
        index = Index(latest: datasetUrl.lastPathComponent, bounds: index.bounds)
        NotificationCenter.default.post(name: OceanCurrentsCache.didChange, object: self)
        if let indexData = try? JSONEncoder().encode(index) {
            let indexUrl = cacheDirectory.appendingPathComponent("index.json")
            _ = try? indexData.write(to: indexUrl)
        }
    }

}
