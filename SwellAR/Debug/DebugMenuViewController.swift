//
//  DebugMenuViewController.swift
//  Museum4
//
//  Created by Michael Schröder on 16.09.18.
//  Copyright © 2018 Refrakt. All rights reserved.
//

import UIKit

class DebugMenuViewController: UITableViewController {

    @IBOutlet weak var colorFactorCell: SliderTableViewCell!
    @IBOutlet weak var fadeOpacityCell: SliderTableViewCell!
    @IBOutlet weak var speedFactorCell: SliderTableViewCell!
    @IBOutlet weak var dropRateCell: SliderTableViewCell!
    @IBOutlet weak var dropRateBumpCell: SliderTableViewCell!
    @IBOutlet weak var resolutionCell: SliderTableViewCell!

    var weatherMap: WeatherMap? {
        didSet {
            if oldValue !== weatherMap {
                DispatchQueue.main.async {
                    self.reloadSliders()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.isScrollEnabled = false
        
        reloadSliders()
        colorFactorCell.valueChangeHandler = { value in
            self.weatherMap?.particleScreen.colorFactor = value
        }
        fadeOpacityCell.valueChangeHandler = { value in
            self.weatherMap?.particleScreen.fadeOpacity = value
        }
        speedFactorCell.valueChangeHandler = { value in
            self.weatherMap?.particleScreen.particleState.speedFactor = value
        }
        dropRateCell.valueChangeHandler = { value in
            self.weatherMap?.particleScreen.particleState.dropRate = value
        }
        dropRateBumpCell.valueChangeHandler = { value in
            self.weatherMap?.particleScreen.particleState.dropRateBump = value
        }
        resolutionCell.valueChangeHandler = { value in
            self.weatherMap?.particleScreen.particleState.resolution = Int(value)
        }
    }
    
    func reloadSliders() {
        guard isViewLoaded else {
            return
        }
        colorFactorCell.value = self.weatherMap?.particleScreen.colorFactor ?? 0
        fadeOpacityCell.value = self.weatherMap?.particleScreen.fadeOpacity ?? 0
        speedFactorCell.value = self.weatherMap?.particleScreen.particleState.speedFactor ?? 0
        dropRateCell.value = self.weatherMap?.particleScreen.particleState.dropRate ?? 0
        dropRateBumpCell.value = self.weatherMap?.particleScreen.particleState.dropRateBump ?? 0
        resolutionCell.value = Float(self.weatherMap?.particleScreen.particleState.resolution ?? 0)
    }

}
