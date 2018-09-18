//
//  ViewController.swift
//  OceaniAR
//
//  Created by Michael Schröder on 18.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import UIKit

class ViewController: ARViewController {

    private var weatherMap: WeatherMap?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(oceanCurrentsCacheAvailableDatasetsDidChange(_:)), name: OceanCurrentsCache.availableDatasetsDidChange, object: nil)
        OceanCurrentsCache.default.update()

        reloadOceanCurrents()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didStartAR() {
        super.didStartAR()        
        
        let dataSetUrl = Bundle.main.url(forResource: "map", withExtension: "xml", subdirectory: "VuforiaDataSets")!
        let dataSet = try! VuforiaDataSet(xmlurl: dataSetUrl)
        arView.activate(dataSet)
    }
    
    override func arView(_ arView: ARView, renderTarget name: String, withModelviewMatrix matrix: GLKMatrix4, atDistance distance: GLfloat, size: CGSize, date: Date) {
        if name == "map" {
            weatherMap?.render(targetSize: size, targetModelView: matrix, arView: arView)
        }
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
    }

}

