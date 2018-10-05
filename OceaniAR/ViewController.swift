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
    
    private var debugging = false
    private var debugNav: UINavigationController!
    private var debugMenuVC: DebugMenuViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.arView.addGestureRecognizer(tapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        self.arView.addGestureRecognizer(doubleTapGesture)
        
        debugNav = self.storyboard?.instantiateViewController(withIdentifier: "DebugNavigationController") as? UINavigationController
        debugMenuVC = (debugNav.viewControllers.first as! DebugMenuViewController)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func didStartAR() {
        let dataSetsUrl = Bundle.main.url(forResource: "VuforiaDataSets", withExtension: nil)!
        let urls = try! FileManager.default.contentsOfDirectory(at: dataSetsUrl, includingPropertiesForKeys: nil, options: [])
        for url in urls.filter({ $0.pathExtension == "xml" }) {
            let dataSet = try! VuforiaDataSet(xmlurl: url)
            self.addTargets(dataSet)
        }
        
        for (name,target) in self.targets {
            maps[name] = Map(target: target)
        }
    }
    
    override func render(_ target: ARViewController.Target) {
        if let map = maps[target.name] {
            map.render()
            if debugging {
                debugMenuVC.weatherMap = map.weatherMap
                debugMenuVC.title = target.name
            }
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
    
    @objc func didDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard !debugging else {
            return
        }
        debugging = true
        self.addChild(debugNav)
        let debugMenuHeight: CGFloat = 346
        debugNav.view.frame = CGRect(x: 0, y: self.view.frame.size.height - debugMenuHeight, width: self.view.frame.size.width, height: debugMenuHeight)
        self.view.addSubview(debugNav.view)
        debugNav.didMove(toParent: self)
    }
    
    @IBAction func unwindDebugMenu(segue: UIStoryboardSegue) {
        debugNav.willMove(toParent: nil)
        debugNav.view.removeFromSuperview()
        debugNav.removeFromParent()
        debugging = false
    }

}

