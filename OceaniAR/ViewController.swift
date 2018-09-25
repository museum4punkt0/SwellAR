//
//  ViewController.swift
//  OceaniAR
//
//  Created by Michael Schröder on 18.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import UIKit

class Target {
    let name: String
    let size: CGSize
    var visible: Bool = false
    var modelViewMatrix: GLKMatrix4 = GLKMatrix4Identity
    var distance: Float = 0
    
    init(_ vuforiaImageTarget: VuforiaImageTarget) {
        self.name = vuforiaImageTarget.name
        self.size = CGSize(width: CGFloat(vuforiaImageTarget.width), height: CGFloat(vuforiaImageTarget.height))
    }
}

class ViewController: ARViewController {

    private var weatherMap: WeatherMap?
    private var touchIcons: [TouchIcon] = []
    
    private var targets: [String: Target] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(oceanCurrentsCacheAvailableDatasetsDidChange(_:)), name: OceanCurrentsCache.availableDatasetsDidChange, object: nil)
        OceanCurrentsCache.default.update()

        reloadOceanCurrents()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.arView.addGestureRecognizer(tapGesture)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didStartAR() {
        super.didStartAR()        
        
        let dataSetUrl = Bundle.main.url(forResource: "map", withExtension: "xml", subdirectory: "VuforiaDataSets")!
        let dataSet = try! VuforiaDataSet(xmlurl: dataSetUrl)
        arView.activate(dataSet)
        
        for vuforiaTarget in dataSet.targets {
            targets[vuforiaTarget.name] = Target(vuforiaTarget)
        }
    }
    
    override func arView(_ arView: ARView, targetDidAppear name: String, at date: Date) {
        targets[name]?.visible = true
    }
    
    override func arView(_ arView: ARView, renderTarget name: String, withModelviewMatrix matrix: GLKMatrix4, atDistance distance: GLfloat, date: Date) {
        guard let target = targets[name] else {
            return
        }
        target.modelViewMatrix = matrix
        target.distance = distance
        
        if target.name == "map" {
            weatherMap?.render(targetSize: target.size, targetModelView: matrix, arView: arView)
            for icon in touchIcons {
                icon.render(on: target, in: arView)
            }
        }
    }
    
    override func arView(_ arView: ARView, targetDidDisappear name: String, at date: Date) {
        targets[name]?.visible = false
    }
    
    @objc func oceanCurrentsCacheAvailableDatasetsDidChange(_ note: Notification) {
        reloadOceanCurrents()
    }
    
    func reloadOceanCurrents() {
        guard let latestUrl = OceanCurrentsCache.default.availableDatasets.last else {
            print("error loading ocean currents: none available")
            return
        }
        OceanCurrents.load(contentsOf: latestUrl, sharegroup: arView.context.sharegroup) { oceanCurrents, error in
            guard let oceanCurrents = oceanCurrents else {
                if let error = error {
                    print("error loading ocean currents: \(error)")
                } else {
                    print("error loading ocean currents")
                }
                return
            }
            
            if let weatherMap = self.weatherMap {
                weatherMap.particleScreen.particleState.oceanCurrents = oceanCurrents
            } else {
                self.initWeatherMap(oceanCurrents: oceanCurrents)
            }
            
            print("ocean currents loaded: \(oceanCurrents.metadata.dataset)")
        }
    }
    
    func initWeatherMap(oceanCurrents: OceanCurrents) {
        let config = Config.default
        let context = EAGLContext(api: self.arView.context.api, sharegroup: self.arView.context.sharegroup)
        EAGLContext.setCurrent(context)
        let weatherMap = WeatherMap(width: config.mapWidth, height: config.mapHeight, oceanCurrents: oceanCurrents)
        weatherMap.particleScreen.colorFactor = config.colorFactor
        weatherMap.particleScreen.fadeOpacity = config.fadeOpacity
        weatherMap.particleScreen.particleState.speedFactor = config.speedFactor
        weatherMap.particleScreen.particleState.dropRate = config.dropRate
        weatherMap.particleScreen.particleState.dropRateBump = config.dropRateBump
        weatherMap.particleScreen.particleState.resolution = config.resolution
        self.weatherMap = weatherMap
        
        initTouchIcons()  // TODO: init on first render?
    }
    
    func initTouchIcons() {
        self.touchIcons = []
        for item in TouchItems.default.items {
            guard let image = UIImage(named: item.icon)?.cgImage else {
                print("error: unknown icon: \(item.icon)")
                continue
            }
            let icon = TouchIcon(image: image)
            icon.x = CGFloat(item.x) / CGFloat(TouchItems.default.width)
            icon.y = CGFloat(item.y) / CGFloat(TouchItems.default.height)
            icon.radius = CGFloat(item.radius) / CGFloat(TouchItems.default.width)
            icon.href = item.href
            self.touchIcons.append(icon)
        }
    }
    
    @objc func didTap(_ gesture: UITapGestureRecognizer) {
        guard case .ended = gesture.state else {
            return
        }        
        let touchInView = gesture.location(in: self.arView)
        for target in targets.values.filter({$0.visible}) {
            let touchInTarget = arView.convert(touchInView, toModelviewMatrix: target.modelViewMatrix, size: GLKVector2Make(Float(target.size.width), Float(target.size.height)))
            if let icon = touchIcons.first(where: {$0.hitTest(touchInTarget, in: target)}) {
                print(icon.href)  // TODO: play video / show photo
            }
        }
    }

}

