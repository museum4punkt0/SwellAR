// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import UIKit
import AVKit

/// A `UIViewController` subclass that manages an `ARView`.
///
/// The `ARViewController` does the following for you:
///
/// - Requesting camera access and dealing with rejection (by pointing the user to enable camera permissions in Settings).
/// - Initializing Vuforia and handling any related errors.
/// - Setting up an `ARView` and implementing the `ARViewDelegate`.
///
/// It also provides a `Target` class to simplify the tracking and rendering of image targets. The `render(_:)` method is called once per frame for each currently visible target.
///
/// Subclasses should override `didStartAR()` to perform additional initialization after Vuforia has been initialized. This is also a good point to load targets from a target database (see `addTargets(_:)`).
///
open class ARViewController: UIViewController, ARViewDelegate {
    
    /// An object representing a trackable image.
    public final class Target {
        
        let arView: ARView
        
        /// The Vuforia target name.
        let name: String
        
        /// The size of the target in world units (usually meters).
        let size: CGSize
        
        /// Wether the target is currently visible or not.
        fileprivate(set) var visible: Bool = false
        
        /// The model view matrix of the target in 3D space.
        fileprivate(set) var modelViewMatrix: GLKMatrix4 = GLKMatrix4Identity
        
        /// The distance of the target to the camera, in world units (usually meters).
        fileprivate(set) var distance: Float = 0
        
        fileprivate init(_ vuforiaImageTarget: VuforiaImageTarget, arView: ARView) {
            self.arView = arView
            self.name = vuforiaImageTarget.name
            self.size = CGSize(width: CGFloat(vuforiaImageTarget.width), height: CGFloat(vuforiaImageTarget.height))
        }
    }

    /// The active targets of the `ARView`, indexed by their Vuforia target name. Use `addTargets(_:)` to add targets from a data set.
    private(set) var targets: [String: Target] = [:]
    
    public final var arView: ARView!
    
    private var cameraAccessLabel: UILabel?
    private var cameraAccessButton: UIButton?
    private var vuforiaErrorLabel: UILabel?
    private var vuforiaRetryButton: UIButton?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        arView = ARView(frame: self.view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.videoGravity = .resizeAspectFill
        arView.videoOrientation = .portrait
        arView.delegate = self
        self.view.insertSubview(arView, at: 0)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        self.requestCameraAccess {
            self.initVuforia()
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Camera Access
    
    private func requestCameraAccess(completion: (() -> Void)?) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.hideCameraAccessUI()
                    completion?()
                } else {
                    self.showCameraAccessUI()
                }
            }
        }
    }
    
    private func showCameraAccessUI() {
        guard cameraAccessButton == nil && cameraAccessLabel == nil else {
            return
        }
        
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("camera-access.button.title", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(enableCameraAccess(_:)), for: .touchUpInside)
        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        let label = UILabel()
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.textAlignment = .center
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        label.text = String.localizedStringWithFormat(NSLocalizedString("camera-access.label", comment: ""), appName)
        self.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        label.widthAnchor.constraint(lessThanOrEqualToConstant: 260).isActive = true
        label.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -8).isActive = true
        label.sizeToFit()
        
        cameraAccessButton = button
        cameraAccessLabel = label
    }
    
    private func hideCameraAccessUI() {
        cameraAccessButton?.removeFromSuperview()
        cameraAccessLabel?.removeFromSuperview()
        cameraAccessButton = nil
        cameraAccessLabel = nil
    }
    
    @objc func enableCameraAccess(_ sender: Any) {
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(settingsUrl)
        }
    }
    
    // MARK: - Vuforia Initialization
    
    private func initVuforia() {
        guard !ARView.isVuforiaInitialized() else {
            self.hideVuforiaErrorUI()
            if !self.arView.isStarted {
                self.arView.start()
                self.didStartAR()
            }
            return
        }
        
        let key = Bundle.main.object(forInfoDictionaryKey: "VuforiaLicenseKey") as? String ?? ""
        ARView.initializeVuforia(withLicenseKey: key) { (result, errorCode) in
            DispatchQueue.main.async {
                switch result {
                case .OK:
                    self.hideVuforiaErrorUI()
                    self.arView.start()
                    self.didStartAR()
                    
                default:
                    self.showVuforiaErrorUI(errorCode: errorCode)
                }
            }
        }
    }
    
    private func showVuforiaErrorUI(errorCode: Int32) {
        guard vuforiaRetryButton == nil && vuforiaErrorLabel == nil else {
            return
        }
        
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("vuforia.error-alert.button.retry", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(retryInitVuforia(_:)), for: .touchUpInside)
        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        
        let label = UILabel()
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.textAlignment = .center
        let title = NSLocalizedString("vuforia.error-alert.title", comment: "")
        label.text = "\(title)\n(Vuforia Error \(errorCode))"
        self.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        label.widthAnchor.constraint(lessThanOrEqualToConstant: 260).isActive = true
        label.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -8).isActive = true
        label.sizeToFit()
        
        vuforiaRetryButton = button
        vuforiaErrorLabel = label
    }
    
    private func hideVuforiaErrorUI() {
        vuforiaRetryButton?.removeFromSuperview()
        vuforiaErrorLabel?.removeFromSuperview()
        vuforiaRetryButton = nil
        vuforiaErrorLabel = nil
    }
    
    @objc func retryInitVuforia(_ sender: Any) {
        hideVuforiaErrorUI()
        self.initVuforia()
    }
    
    // MARK: - Target management
    
    /// Called after AR has started. For subclasses to override.
    open func didStartAR() {
    }
    
    /// Add all image targets from the given the Vuforia data set.
    func addTargets(_ dataSet: VuforiaDataSet) {
        arView.activate(dataSet)
        for vuforiaTarget in dataSet.targets {
            let target = Target(vuforiaTarget, arView: arView)
            targets[vuforiaTarget.name] = target
        }
    }
    
    /// Convenience method called by `arView(_:renderTarget:withModelviewMatrix:atDistance:date)`. You can do your target rendering here.
    open func render(_ target: Target) {
        
    }
    
    // MARK: - ARViewDelegate
    
    open func arView(_ arView: ARView, targetDidAppear name: String, at date: Date) {
        targets[name]?.visible = true
    }
    
    open func arView(_ arView: ARView, renderTarget name: String, withModelviewMatrix matrix: GLKMatrix4, atDistance distance: GLfloat, date: Date) {
        guard let target = targets[name] else {
            return
        }
        target.modelViewMatrix = matrix
        target.distance = distance
        render(target)
    }
    
    open func arView(_ arView: ARView, targetDidDisappear name: String, at date: Date) {
        targets[name]?.visible = false
    }
    
}
