//
//  Chart.swift
//  CryptoWalletTest
//
//  Created by Матвей Анисович on 6/11/21.
//

import UIKit

class Chart: UIView {
    
    var chart: CALayer?
    var pathLayer: CAShapeLayer?
    
    var pricesLabelTexts:[Double] = []
    var prices: [CoinCap.PricePoint] = []
    var max = 0.0
    var min = 0.0
    
    let purpleColor = UIColor(red: 109.0/255.0, green: 96.0/255.0, blue: 173.0/255.0, alpha: 1.0).cgColor
    
    var selectedPeriod = 4 * 60 * 60
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    func setup() {
        if prices.isEmpty { return }
        
        for subview in subviews {
            UIView.animate(withDuration: 0.15, animations: {
                subview.alpha = 0
            },completion: { _ in
                subview.removeFromSuperview()
            })
        }
        chart?.removeFromSuperlayer()
        pathLayer?.removeFromSuperlayer()
        
        // Chart
        let last = prices.last!
        while prices.count > 100 {
            var newData: [CoinCap.PricePoint] = []
            for (i,point) in prices.enumerated() {
                if i % 3 != 0 {
                    newData.append(point)
                }
            }
            prices = newData
        }
        // Keep the last point up-to-date
        prices.removeLast()
        prices.append(last)
        
        setupLabelValues()
        setupDateLabels()
        
        let path = UIBezierPath() // From top left
        path.move(to: CGPoint(x: 0, y: yPos(prices.first!.price)))
        let xDif = frame.width / CGFloat(prices.count - 1)
        for (i,point) in prices.enumerated() {
            path.addLine(to: CGPoint(x: xDif * CGFloat(i), y: yPos(point.price)))
        }
        path.addLine(to: CGPoint(x: frame.width + 20, y: yPos(prices.last!.price)))
        path.addLine(to: CGPoint(x: frame.width + 20, y: frame.height + 1000))
        path.addLine(to: CGPoint(x: -20, y: frame.height + 1000))
        path.addLine(to: CGPoint(x: -20, y: yPos(prices.first!.price)))
        pathLayer = CAShapeLayer()
        pathLayer!.path = path.cgPath
        pathLayer!.fillColor = UIColor.clear.cgColor
        pathLayer!.lineWidth = 3
        pathLayer!.strokeColor = purpleColor
        layer.addSublayer(pathLayer!)
        
        // Fill with gradient
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: path.bounds.minY, width: frame.width, height: frame.height - path.bounds.minY)
        gradient.colors = [purpleColor, UIColor.clear.cgColor]
        gradient.opacity = 0.5
        gradient.endPoint = CGPoint(x: 0.5, y: 0.9)
        let pathMask = CAShapeLayer()
        let maskPath = path.copy() as! UIBezierPath
        maskPath.apply(CGAffineTransform(translationX: 0, y: -path.bounds.minY))
        pathMask.path = maskPath.cgPath
        print(maskPath.cgPath.boundingBoxOfPath)
        gradient.mask = pathMask
        self.layer.addSublayer(gradient)
        
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        animation.fromValue = 0.0
        animation.toValue = 0.5
        animation.duration = 0.25
        animation.timingFunction = CAMediaTimingFunction(name: .default)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        gradient.add(animation, forKey: "fade")
        
        
        chart = gradient
        
        // Labels on the left and lines
        for i in 0...6 {
            let distance = (frame.height - 64) / 6
            let label = UILabel(frame: CGRect(x: 20, y: distance * CGFloat(i), width: 100, height: 19))
            
            label.text = "$ \(formatNumber(pricesLabelTexts[i]))" // doublePrice(pricesLabelTexts[i])
            label.font = .systemFont(ofSize: 11)
            label.textColor = .white
            label.alpha = 0
            addSubview(label)
            
            UIView.animate(withDuration: 0.5, animations: {
                label.alpha = 1
            })
            
            let line = UIView(frame: CGRect(x: label.frame.minX, y: label.frame.maxY + 4, width: frame.width - label.frame.minX * 2, height: 0.5))
            line.backgroundColor = .init(red: 80 / 255, green: 84 / 255, blue: 97 / 255, alpha: 0.5)
            addSubview(line)
        }
    }
    
    func setupDateLabels() {
        let date = Date()
        let dist = frame.width / 6
        
        for i in 0...5 {
            let i1 = 5 - i
            let formatter = DateFormatter()
            
            if selectedPeriod == 4 * 60 * 60 {
                formatter.dateFormat = "HH'h00'"
            } else {
                formatter.dateFormat = "MMM d"
            }
            let text = formatter.string(from: date.addingTimeInterval(-TimeInterval(i1 * selectedPeriod)))
            let label = UILabel(frame: CGRect(x: dist * CGFloat(i) + 20, y: frame.height - 24, width: dist, height: 19))
            label.text = text
            label.font = .systemFont(ofSize: 11)
            label.textColor = .white
            label.alpha = 0
            addSubview(label)
            
            UIView.animate(withDuration: 0.5, animations: {
                label.alpha = 1
            })
        }
    }
    
    func yPos(_ price: Double) -> CGFloat {
        let dollarInPoints = (frame.height - 64) / CGFloat(pricesLabelTexts.first! - pricesLabelTexts.last!)
        let dollarsFromMinPrice = price - pricesLabelTexts.last!
        let res = (frame.height - 64) - dollarInPoints * CGFloat(dollarsFromMinPrice)
        
        
        return res
    }
    
    func setupLabelValues() {
        pricesLabelTexts = []
        
        min = Double(Int32.max) // A high number
        max = 0.0
        for p in prices { if p.price > max { max = p.price }; if p.price < min { min = p.price }}
        let allowedDifferences = [0.0001, 0.001, 0.01, 0.1, 0.25, 0.33, 0.5, 1, 2, 5, 10, 15, 25, 50, 75, 100, 150, 200, 300, 400, 500, 650, 750, 850, 1000, 1250, 1500, 1750, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 7500, 10000, 15000, 20000] // Could be a better solution
        let aprox = abs(max - min) / 7
        var distance = Double(Int32.max)
        
        var valueDistanceBetweenLabels = 0.0
        
        for n in allowedDifferences {
            if abs(aprox - n) < distance {
                distance = abs(aprox - n)
            } else {
                valueDistanceBetweenLabels = n
                break
            }
        }
        
//        let minLabelValue = floor(min / valueDistanceBetweenLabels) * valueDistanceBetweenLabels
        let maxLabelValue = ceil(max / valueDistanceBetweenLabels) * valueDistanceBetweenLabels
        
        for i in 0...6 {
            pricesLabelTexts.append(maxLabelValue - valueDistanceBetweenLabels * Double(i))
        }
    }
    func formatNumber(_ number: Double) -> String {
        let suffix = ["", "k", "m"]
        var index = 0
        var value = number
        while value / 1000 >= 10 {
            value = value / 1000
            index += 1
        }
        return String(format: "%.2f%@", value, suffix[index])
    }
}
