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
    let touchItems: TouchItems
    
    private var loading = false
    private(set) var weatherMap: WeatherMap? = nil
    private(set) var touchIcons: [TouchIcon] = []
    
    init(target: ARViewController.Target) {
        self.target = target
        self.oceanCurrentsCache = OceanCurrentsCache(mapName: target.name)

        let bundleUrl = Map.bundleUrl(for: target.name)
        let decoder = JSONDecoder()
        
        let touchItemsUrl = bundleUrl.appendingPathComponent("touch_items.json")
        let touchItemsData = try! Data(contentsOf: touchItemsUrl)
        self.touchItems = try! decoder.decode(TouchItems.self, from: touchItemsData)

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
        self.weatherMap = WeatherMap(config: config, oceanCurrents: oceanCurrents)
    }
    
    private func loadTouchItems() {
        let bundleUrl = Map.bundleUrl(for: self.target.name)
        let touchItemsUrl = bundleUrl.appendingPathComponent("touch_items.json")
        guard FileManager.default.fileExists(atPath: touchItemsUrl.path) else {
            return
        }
        do {
            let touchItemsData = try Data(contentsOf: touchItemsUrl)
            let touchItems = try JSONDecoder().decode(TouchItems.self, from: touchItemsData)
            self.touchIcons.removeAll()
            for item in touchItems.items {
                guard let image = UIImage(named: item.icon)?.cgImage else {
                    print("\(target.name): ignoring unknown touch item icon: \(item.icon)")
                    continue
                }
                let icon = TouchIcon(image: image)
                icon.x = CGFloat(item.x) / CGFloat(touchItems.width)
                icon.y = CGFloat(item.y) / CGFloat(touchItems.height)
                icon.radius = CGFloat(item.radius) / CGFloat(touchItems.width)
                icon.href = item.href
                self.touchIcons.append(icon)
            }
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
        for icon in touchIcons {
            icon.render(on: target)
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
