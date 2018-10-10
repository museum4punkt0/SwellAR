//
//  Map.swift
//  OceaniAR
//
//  Created by Michael Schröder on 25.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import Foundation

class Map {
    
    let target: ARViewController.Target
    let oceanCurrentsCache: OceanCurrentsCache
    
    private var loading = false
    private(set) var weatherMap: WeatherMap? = nil
    private(set) var touchItems: [TouchItem] = []
    
    init(target: ARViewController.Target) {
        self.target = target
        self.oceanCurrentsCache = OceanCurrentsCache(mapName: target.name)
        NotificationCenter.default.addObserver(self, selector: #selector(oceanCurrentsCacheDidChange(_:)), name: OceanCurrentsCache.didChange, object: oceanCurrentsCache)
    }
    
    func load() {
        guard !loading, weatherMap == nil else {
            return
        }
        loading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let ctx = EAGLContext(api: .openGLES2, sharegroup: self.target.arView.context.sharegroup)
            EAGLContext.setCurrent(ctx)
            self.loadWeatherMap()
            self.loadTouchItems()
            self.oceanCurrentsCache.update()
            self.loading = false
        }
    }
    
    private func loadWeatherMap() {
        let bundleUrl = Map.bundleUrl(for: self.target.name)
        let configUrl = bundleUrl.appendingPathComponent("config.json")
        let configData = try! Data(contentsOf: configUrl)
        let config = try! JSONDecoder().decode(WeatherMap.Config.self, from: configData)
        let oceanCurrents = try! OceanCurrents(contentsOf: self.oceanCurrentsCache.latestDataset)
        let maskUrl = bundleUrl.appendingPathComponent("mask.png")
        let maskTexture: GLuint
        if FileManager.default.fileExists(atPath: maskUrl.path) {
            let textureInfo = try! GLKTextureLoader.texture(withContentsOf: maskUrl, options: [GLKTextureLoaderOriginBottomLeft: true])
            maskTexture = textureInfo.name
        } else {
            let allWhite: [GLubyte] = [255,255,255,255]
            maskTexture = createTexture(width: 1, height: 1, data: allWhite)
        }
        self.weatherMap = WeatherMap(config: config, oceanCurrents: oceanCurrents, maskTexture: maskTexture)
    }
    
    private func loadTouchItems() {
        let bundleUrl = Map.bundleUrl(for: self.target.name)
        let touchItemsUrl = bundleUrl.appendingPathComponent("touch_items.json")
        guard FileManager.default.fileExists(atPath: touchItemsUrl.path) else {
            return
        }
        do {
            self.touchItems = try TouchItem.touchItems(contentsOf: touchItemsUrl)
        } catch let error {
            print("\(target.name): error loading touch items: \(error)")
        }
    }
    
    @objc func oceanCurrentsCacheDidChange(_ note: Notification) {
        DispatchQueue.global(qos: .userInitiated).async {
            let ctx = EAGLContext(api: .openGLES2, sharegroup: self.target.arView.context.sharegroup)
            EAGLContext.setCurrent(ctx)
            do {
                let oceanCurrents = try OceanCurrents(contentsOf: self.oceanCurrentsCache.latestDataset)
                self.weatherMap?.particleScreen.particleState.oceanCurrents = oceanCurrents
            } catch let error {
                print("\(self.target.name): error loading ocean currents from \(self.oceanCurrentsCache.latestDataset): \(error)")
            }
        }
    }
    
    func render() {
        guard let weatherMap = weatherMap else {
            load()
            return
        }
        weatherMap.render(on: target)
        for item in touchItems {
            item.render(on: target)
        }
    }

}

extension Map {

    static func localUrl(for name: String) -> URL {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let mapsDir = appSupportDir.appendingPathComponent("Maps", isDirectory: true)
        return mapsDir.appendingPathComponent(name, isDirectory: true)
    }
    
    static func bundleUrl(for name: String) -> URL {
        return Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Maps")!
    }

}
