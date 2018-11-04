// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

import UIKit

@IBDesignable
class SliderTableViewCell: UITableViewCell {
    
    @IBInspectable var minValue: Float = 0
    @IBInspectable var maxValue: Float = 1
    @IBInspectable var isReal: Bool = true
    @IBInspectable var isContinuous: Bool = true
    
    private var _value: Float = 0
    @IBInspectable var value: Float {
        set {
            if newValue < minValue {
                _value = minValue
            } else if newValue > maxValue {
                _value = maxValue
            } else {
                _value = newValue
            }
            if !isReal {
                _value = round(_value)
            }
            valueChangeHandler?(_value)
            DispatchQueue.main.async {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.sliderLayer.frame.size.width = self.position(from: self._value)
                self.updateDetailText(with: self._value)
                CATransaction.commit()
            }
        }
        get {
            return _value
        }
    }
    
    @IBInspectable var sliderColor: UIColor = #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1)
    @IBInspectable var discontinuousSliderColor: UIColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    
    var valueChangeHandler: ((Float) -> Void)?
    
    private var sliderLayer: CALayer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sliderLayer = CALayer()
        sliderLayer.frame = CGRect(x: 0, y: 0, width: 100, height: self.layer.frame.height)
        sliderLayer.backgroundColor = sliderColor.cgColor
        self.layer.insertSublayer(sliderLayer, at: 0)
        
        self.selectionStyle = .none
        self.textLabel?.isOpaque = false
        self.textLabel?.backgroundColor = nil
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let position = touch.location(in: self).x
        let value = self.value(from: position)
        if isContinuous {
            self.value = value
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.sliderLayer.frame.size.width = position
            self.sliderLayer.backgroundColor = discontinuousSliderColor.cgColor
            self.detailTextLabel?.textColor = UIColor.red
            updateDetailText(with: value)
            CATransaction.commit()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let position = touch.location(in: self).x
        self.value = value(from: position)
        sliderLayer.backgroundColor = sliderColor.cgColor
        self.detailTextLabel?.textColor = UIColor.darkText
    }
    
    private func updateDetailText(with value: Float) {
        if self.isReal {
            self.detailTextLabel?.text = String(value)
        } else {
            self.detailTextLabel?.text = String(Int(value))
        }
    }
    
    private func position(from value: Float) -> CGFloat {
        return CGFloat((Float(self.bounds.size.width) * (value - minValue)) / (maxValue - minValue))
    }
    
    private func value(from position: CGFloat) -> Float {
        return (((maxValue - minValue) * Float(position)) / Float(self.bounds.size.width)) + minValue
    }

}
