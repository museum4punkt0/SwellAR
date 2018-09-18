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
        
        let oceanCurrentsUrl = Bundle.main.url(forResource: "oscar_vel9472.nc", withExtension: nil, subdirectory: "OceanCurrents")!
        reloadOceanCurrents(contentsOf: oceanCurrentsUrl)
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
    
    func reloadOceanCurrents(contentsOf url: URL) {
        OceanCurrents.load(contentsOf: url, sharegroup: arView.context.sharegroup) { oceanCurrents, error in
            guard let oceanCurrents = oceanCurrents else {
                if let error = error {
                    print("error loading ocean currents: \(error)")
                } else {
                    print("error loading ocean currents")
                }
                return
            }
            
            if self.weatherMap == nil {
                let context = EAGLContext(api: self.arView.context.api, sharegroup: self.arView.context.sharegroup)
                EAGLContext.setCurrent(context)
                self.weatherMap = WeatherMap(width: 1140, height: 836, oceanCurrents: oceanCurrents)
            }
            
            self.weatherMap?.particleScreen.particleState.oceanCurrents = oceanCurrents
        }
    }

}
                

