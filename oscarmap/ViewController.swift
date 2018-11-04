// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var datasetField: NSTextField!
    @IBOutlet weak var latMinField: NSTextField!
    @IBOutlet weak var latMaxField: NSTextField!
    @IBOutlet weak var lonMinField: NSTextField!
    @IBOutlet weak var lonMaxField: NSTextField!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var progressLabel: NSTextField!
    
    var working: Bool = false {
        didSet {
            datasetField.isEnabled = !working
            latMinField.isEnabled = !working
            latMaxField.isEnabled = !working
            lonMinField.isEnabled = !working
            lonMaxField.isEnabled = !working
            downloadButton.isEnabled = !working
            if working {
                progressIndicator.startAnimation(nil)
            } else {
                progressIndicator.stopAnimation(nil)
            }
            progressLabel.isHidden = !working
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func download(_ sender: Any) {
        working = true
        progressLabel.stringValue = "Downloading OSCAR data from PODAAC…"
        
        let dataset = datasetField.stringValue
        let bounds = PODAAC.Bounds.init(
            latMinIndex: latMinField.integerValue,
            latMaxIndex: latMaxField.integerValue,
            lonMinIndex: lonMinField.integerValue,
            lonMaxIndex: lonMaxField.integerValue
        )
        
        PODAAC.downloadOSCAR(dataset: dataset, bounds: bounds) { result in
            switch result {
            case let .error(error):
                DispatchQueue.main.async {
                    if let error = error {
                        NSAlert(error: error).runModal()
                    }
                    self.working = false
                }
                return
            case let .success(oscar):
                self.createTexture(oscar)
            }
        }
    }
    
    private func createTexture(_ oscar: OSCAR) {
        self.working = true
        self.progressLabel.stringValue = "Creating texture image from OSCAR data…"
        guard let (cgImage,metadata) = oscar.createImage() else {
            DispatchQueue.main.async {
                self.working = false
            }
            return
        }
        
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let datasetUrl = downloadsDirectory.appendingPathComponent(oscar.dataset, isDirectory: true)
        let textureUrl = datasetUrl.appendingPathComponent("texture.png")
        let metadataUrl = datasetUrl.appendingPathComponent("metadata.json")
        do {
            try FileManager.default.createDirectory(at: datasetUrl, withIntermediateDirectories: true, attributes: nil)
            writeCGImage(cgImage, to: textureUrl)
            let jsonData = try JSONEncoder().encode(metadata)
            try jsonData.write(to: metadataUrl)
        } catch let error {
            DispatchQueue.main.async {
                NSAlert(error: error).runModal()
                self.working = false
            }
            return
        }
        
        self.working = false
        NSSound(named: NSSound.Name("Glass"))?.play()
    }
    
}

@discardableResult func writeCGImage(_ image: CGImage, to destinationURL: URL) -> Bool {
    guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, kUTTypePNG, 1, nil) else { return false }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination)
}
