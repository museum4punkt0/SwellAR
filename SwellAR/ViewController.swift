// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import UIKit
import AVKit

// Note [Debug Menu]
// -----------------
// To enable the debug menu, which shows up on a double tap and allows fiddling with various particle simulation settings, uncomment all the code marked with [Debug Menu].

class ViewController: ARViewController {
    
    private var maps: [String: Map] = [:]
    
//     // [Debug Menu]
//     private var debugging = false
//     private var debugNav: UINavigationController!
//     private var debugMenuVC: DebugMenuViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.arView.addGestureRecognizer(tapGesture)

//        // [Debug Menu]
//        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap(_:)))
//        doubleTapGesture.numberOfTapsRequired = 2
//        self.arView.addGestureRecognizer(doubleTapGesture)
//
//        debugNav = self.storyboard?.instantiateViewController(withIdentifier: "DebugNavigationController") as? UINavigationController
//        debugMenuVC = (debugNav.viewControllers.first as! DebugMenuViewController)
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

//            // [Debug Menu]
//            if debugging {
//                debugMenuVC.weatherMap = map.weatherMap
//                debugMenuVC.title = target.name
//            }
        }
    }
    
    @objc func didTap(_ gesture: UITapGestureRecognizer) {
        guard case .ended = gesture.state else {
            return
        }        
        let touchInView = gesture.location(in: self.arView)
        for map in maps.values.filter({$0.target.visible}) {
            let touchInTarget = arView.convert(touchInView, toModelviewMatrix: map.target.modelViewMatrix, size: GLKVector2Make(Float(map.target.size.width), Float(map.target.size.height)))
            if let item = map.touchItems.first(where: {$0.hitTest(touchInTarget, in: map.target)}),
                let url = Bundle.main.url(forResource: item.href, withExtension: nil, subdirectory: "Media") {
                if url.pathExtension == "html" {
                    showHTML(url: url)
                } else {
                    playVideo(url: url)
                }
                return
            }
        }
        arView.focus()
    }
    
    @objc func dismissPresentedViewController(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func showHTML(url: URL) {
        let webVC = WebViewController()
        webVC.fileURL = url
        webVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(dismissPresentedViewController(_:)))
        let nav = UINavigationController(rootViewController: webVC)
        nav.navigationBar.barStyle = .black
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.tintColor = UIColor(red: 0.278, green: 0.714, blue: 0.957, alpha: 1)
        nav.navigationBar.barTintColor = UIColor(red:0.00, green:0.10, blue:0.31, alpha:1.0)
        nav.navigationBar.shadowImage = UIImage()
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true)
    }
    
    func playVideo(url: URL) {
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        if #available(iOS 11.0, *) {
            playerController.exitsFullScreenWhenPlaybackEnds = true
        }
        playerController.updatesNowPlayingInfoCenter = false
        self.present(playerController, animated: true) {
            player.play()
        }
    }

//    // [Debug Menu]
//
//    @objc func didDoubleTap(_ gesture: UITapGestureRecognizer) {
//        guard !debugging else {
//            return
//        }
//        debugging = true
//        self.addChild(debugNav)
//        let debugMenuHeight: CGFloat = 346
//        debugNav.view.frame = CGRect(x: 0, y: self.view.frame.size.height - debugMenuHeight, width: self.view.frame.size.width, height: debugMenuHeight)
//        self.view.addSubview(debugNav.view)
//        debugNav.didMove(toParent: self)
//    }
//
//    @IBAction func unwindDebugMenu(segue: UIStoryboardSegue) {
//        debugNav.willMove(toParent: nil)
//        debugNav.view.removeFromSuperview()
//        debugNav.removeFromParent()
//        debugging = false
//    }

}

