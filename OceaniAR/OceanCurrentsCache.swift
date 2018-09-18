//
//  OceanCurrentsCache.swift
//  Museum4
//
//  Created by Michael Schröder on 11.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation
import UIKit

final class OceanCurrentsCache {
    
    static let `default` = OceanCurrentsCache()
    
    static let availableDatasetsDidChange = Notification.Name("OceanCurrentsCacheAvailableDatasetsDidChangeNotification")
    
    /// Index into OSCAR latitude array: 0 = -80N, 420 = 80N, grid size = 1/3
    var latitudes = (124, 411)
    
    /// Index into OSCAR longitude array: 0 = 20E, 1200 = 420E, grid size = 1/3, data repeats in overlap region
    var longitudes = (254, 720)
    
    private(set) var availableDatasets: [URL] = [] {
        didSet {
            NotificationCenter.default.post(name: OceanCurrentsCache.availableDatasetsDidChange, object: self)
        }
    }

    static var directory: URL = {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let oceanCurrentsCacheDir = appSupportDir.appendingPathComponent("OceanCurrents", isDirectory: true)
        try! FileManager.default.createDirectory(at: oceanCurrentsCacheDir, withIntermediateDirectories: true, attributes: [FileAttributeKey(rawValue: URLResourceKey.isExcludedFromBackupKey.rawValue): NSNumber(value: true as Bool)])
        return oceanCurrentsCacheDir
    }()
    
    private init() {
        availableDatasets = (try? FileManager.default.contentsOfDirectory(at: OceanCurrentsCache.directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
        availableDatasets.sort(by: {(u1,u2) in u1.lastPathComponent < u2.lastPathComponent})
        if availableDatasets.isEmpty, let bundleDir = Bundle.main.url(forResource: "OceanCurrents", withExtension: nil) {
            let bundledDatasets = (try? FileManager.default.contentsOfDirectory(at: bundleDir, includingPropertiesForKeys: nil, options: [])) ?? []
            for bundledDataset in bundledDatasets.sorted(by: {(u1,u2) in u1.lastPathComponent < u2.lastPathComponent}) {
                let localDataset = OceanCurrentsCache.directory.appendingPathComponent(bundledDataset.lastPathComponent)
                do {
                    try FileManager.default.copyItem(at: bundledDataset, to: localDataset)
                    availableDatasets.append(localDataset)
                } catch let error {
                    print("error copying dataset from bundle to local cache: \(error)")
                    continue
                }
            }
        }
    }
    
    func update() {
        PODAAC.getLatestOSCARDatasetName { name, error in
            guard let name = name else {
                if let error = error {
                    print("error getting latest OSCAR dataset name: \(error)")
                } else {
                    print("error getting latest OSCAR dataset name")
                }
                return
            }
            print("latest OSCAR dataset: \(name)")
            if self.availableDatasets.map({$0.lastPathComponent}).contains(name) {
                return
            }
            print("downloading \(name)")
            PODAAC.downloadOSCAR(dataset: name, latitude: self.latitudes, longitude: self.longitudes) { oscar, error in
                guard let oscar = oscar else {
                    if let error = error {
                        print("error downloading OSCAR data: \(error)")
                    } else {
                        print("error downloading OSCAR data")
                    }
                    return
                }
                self.addDataset(oscar: oscar)
            }
        }
    }
    
    private func addDataset(oscar: OSCAR) {
        guard
            let (image, metadata) = oscar.createImage(),
            let pngData = UIImage(cgImage: image).pngData()
        else {
            print("error creating image from OSCAR dataset \(oscar.dataset)")
            return
        }
        let datasetUrl = OceanCurrentsCache.directory.appendingPathComponent(oscar.dataset, isDirectory: true)
        let textureUrl = datasetUrl.appendingPathComponent("texture.png")
        let metadataUrl = datasetUrl.appendingPathComponent("metadata.json")
        do {
            try FileManager.default.createDirectory(at: datasetUrl, withIntermediateDirectories: true, attributes: nil)
            try pngData.write(to: textureUrl)
            let jsonData = try JSONEncoder().encode(metadata)
            try jsonData.write(to: metadataUrl)
        } catch let error {
            print("error caching image and/or metadata for OSCAR dataset \(oscar.dataset): \(error)")
            return
        }
        availableDatasets.append(datasetUrl)
    }

}
