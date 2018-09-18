//
//  WeatherMap.swift
//  OceaniAR
//
//  Created by Michael Schröder on 18.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//
//  based on https://github.com/mapbox/webgl-wind
//

import Foundation

class WeatherMap {
        
    let particleScreen: ParticleScreen
    let plane: SimplePlane
    
    init(width: Int, height: Int, oceanCurrents: OceanCurrents) {
        let particleState = ParticleState(oceanCurrents: oceanCurrents)
        let colorRamp = ColorRamp(colors: ColorRamp.defaultColors)
        self.particleScreen = ParticleScreen(width: width, height: height, particleState: particleState, colorRamp: colorRamp)
        self.plane = SimplePlane(width: width, height: height)
    }
    
    func render(targetSize: CGSize, targetModelView: GLKMatrix4, arView: ARView) {        
        particleScreen.particleState.update()
        particleScreen.draw()
        plane.render(texture: particleScreen.texture, targetSize: targetSize, targetModelView: targetModelView, arView: arView)
    }
    
}
