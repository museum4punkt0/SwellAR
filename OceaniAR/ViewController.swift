//
//  ViewController.swift
//  OceaniAR
//
//  Created by Michael Schröder on 18.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import UIKit

class Target {
    let arView: ARView
    let name: String
    let size: CGSize
    var visible: Bool = false
    var modelViewMatrix: GLKMatrix4 = GLKMatrix4Identity
    var distance: Float = 0
    
    init(_ vuforiaImageTarget: VuforiaImageTarget, arView: ARView) {
        self.arView = arView
        self.name = vuforiaImageTarget.name
        self.size = CGSize(width: CGFloat(vuforiaImageTarget.width), height: CGFloat(vuforiaImageTarget.height))
    }
}

class ViewController: ARViewController {
    
    private var targets: [String: Target] = [:]
    private var maps: [String: Map] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.arView.addGestureRecognizer(tapGesture)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didStartAR() {
        super.didStartAR()        
        
        let dataSetUrl = Bundle.main.url(forResource: "maps", withExtension: "xml", subdirectory: "VuforiaDataSets")!
        let dataSet = try! VuforiaDataSet(xmlurl: dataSetUrl)
        arView.activate(dataSet)
        
        for vuforiaTarget in dataSet.targets {
            let target = Target(vuforiaTarget, arView: arView)
            targets[vuforiaTarget.name] = target
            maps[vuforiaTarget.name] = Map(target: target)
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
        
        if let map = maps[target.name] {
            map.render()
        }
    }
    
    override func arView(_ arView: ARView, targetDidDisappear name: String, at date: Date) {
        targets[name]?.visible = false
    }
    
    @objc func didTap(_ gesture: UITapGestureRecognizer) {
        guard case .ended = gesture.state else {
            return
        }        
        let touchInView = gesture.location(in: self.arView)
        for map in maps.values.filter({$0.target.visible}) {
            let touchInTarget = arView.convert(touchInView, toModelviewMatrix: map.target.modelViewMatrix, size: GLKVector2Make(Float(map.target.size.width), Float(map.target.size.height)))
            if let icon = map.touchIcons.first(where: {$0.hitTest(touchInTarget, in: map.target)}) {
                print(icon.href)  // TODO: play video / show photo
            }
        }
    }

}

