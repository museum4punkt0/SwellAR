// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import Foundation

/// A particle simulation of actual ocean currents.
///
/// Based on https://github.com/mapbox/webgl-wind
///
class WeatherMap {
        
    let particleScreen: ParticleScreen
    let plane: SimplePlane
    let maskTexture: GLuint
    
    struct Config: Codable {
        let mapWidth: Int
        let mapHeight: Int
        let fadeOpacity: Float
        let colorFactor: Float
        let speedFactor: Float
        let dropRate: Float
        let dropRateBump: Float
        let resolution: Int
        let colors: [HexColor]
    }
    
    init(config: Config, oceanCurrents: OceanCurrents, maskTexture: GLuint) {
        let particleState = ParticleState(resolution: config.resolution, oceanCurrents: oceanCurrents)
        particleState.speedFactor = config.speedFactor
        particleState.dropRate = config.dropRate
        particleState.dropRateBump = config.dropRateBump
        let colors = config.colors.map{$0.uiColor.cgColor}
        let colorRamp = ColorRamp(colors: colors)
        particleScreen = ParticleScreen(width: config.mapWidth, height: config.mapHeight, particleState: particleState, colorRamp: colorRamp)
        particleScreen.colorFactor = config.colorFactor
        particleScreen.fadeOpacity = config.fadeOpacity
        self.plane = SimplePlane(width: config.mapWidth, height: config.mapHeight)
        self.maskTexture = maskTexture
    }
    
    func render(on target: ARViewController.Target) {
        particleScreen.particleState.update()
        particleScreen.draw()
        plane.render(texture: particleScreen.texture, mask: maskTexture, on: target)
    }
    
}
