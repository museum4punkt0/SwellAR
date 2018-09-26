//
//  ViewController.swift
//  OceaniAR
//
//  Created by Michael Schröder on 18.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import UIKit


class ViewController: ARViewController {
    
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
        let dataSetUrl = Bundle.main.url(forResource: "maps", withExtension: "xml", subdirectory: "VuforiaDataSets")!
        let dataSet = try! VuforiaDataSet(xmlurl: dataSetUrl)
        self.addTargets(dataSet)
        
        for (name,target) in self.targets {
            maps[name] = Map(target: target)
        }
    }
    
    override func render(_ target: ARViewController.Target) {
        if let map = maps[target.name] {
            map.render()
        }
    }
    
    
    @objc func didTap(_ gesture: UITapGestureRecognizer) {
        guard case .ended = gesture.state else {
            return
        }        
        let touchInView = gesture.location(in: self.arView)
        for map in maps.values.filter({$0.target.visible}) {
            let touchInTarget = arView.convert(touchInView, toModelviewMatrix: map.target.modelViewMatrix, size: GLKVector2Make(Float(map.target.size.width), Float(map.target.size.height)))
            if let item = map.touchItems.first(where: {$0.hitTest(touchInTarget, in: map.target)}) {
                print(item.href)  // TODO: play video / show photo
            }
        }
    }

}

