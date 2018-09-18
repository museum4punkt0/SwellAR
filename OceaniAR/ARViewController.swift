//
//  ARViewController.swift
//  OceaniAR
//
//  Created by Michael Schröder on 18.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import UIKit
import AVKit

open class ARViewController: UIViewController, ARViewDelegate {
    
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
            self.arView.start()
            self.didStartAR()
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
    
    /// Called after AR has started. For subclasses to override.
    open func didStartAR() {
    }
    
    // MARK: - ARViewDelegate
    
    open func arView(_ arView: ARView, targetDidAppear name: String, at date: Date) {
        
    }
    
    open func arView(_ arView: ARView, renderTarget name: String, withModelviewMatrix matrix: GLKMatrix4, atDistance distance: GLfloat, size: CGSize, date: Date) {
        
    }
    
    open func arView(_ arView: ARView, targetDidDisappear name: String, at date: Date) {
        
    }
    
}
