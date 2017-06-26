//
//  PlayControlButton.swift
//  notGIF
//
//  Created by ooatuoo on 2017/6/19.
//  Copyright © 2017年 xyz. All rights reserved.
//

import UIKit

fileprivate let outerCycleDia: CGFloat = 20
fileprivate let lineWidth: CGFloat = 1.6
fileprivate let lineLength: CGFloat = outerCycleDia*0.44
fileprivate let strokeColor: UIColor = UIColor.textTint
fileprivate let lineSpace: CGFloat = 0.6 * lineLength

class PlayControlButton: UIButton {
    fileprivate var tapHandler: ((Bool) -> Void)?
    
    fileprivate var containerLayer: CALayer!
    fileprivate var rightLineALayer: CAShapeLayer!
    fileprivate var rightLineBLayer: CAShapeLayer!
    fileprivate var rightLinePaths: [CGPath] = []
    
    fileprivate var showPlay: Bool = false
    fileprivate var throttleTimer: DispatchSourceTimer?
    
    init(showPlay: Bool, tapHandler: @escaping (Bool) -> Void) {
        let diameter = outerCycleDia+lineWidth
        super.init(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        
        self.showPlay = showPlay
        self.tapHandler = tapHandler
        
        backgroundColor = .clear
        
        let outerCycleLayer = CAShapeLayer()
        outerCycleLayer.frame = bounds
        let outerCyclePath = UIBezierPath(ovalIn: bounds.insetBy(dx: lineWidth/2, dy: lineWidth/2))
        outerCycleLayer.contentsScale = UIScreen.main.scale
        outerCycleLayer.fillColor = UIColor.clear.cgColor
        outerCycleLayer.path = outerCyclePath.cgPath
        outerCycleLayer.lineWidth = lineWidth
        outerCycleLayer.strokeColor = strokeColor.cgColor
        
        layer.addSublayer(outerCycleLayer)
        
        containerLayer = CALayer()
        containerLayer.frame = bounds
        containerLayer.backgroundColor = UIColor.clear.cgColor
        
        layer.addSublayer(containerLayer)
        
        let leftLinePath = UIBezierPath()
        let leftUPoint = CGPoint(x: diameter/2 - lineSpace/2, y: (diameter-lineLength)/2)
        let leftDPoint = CGPoint(x: diameter/2 - lineSpace/2, y: (diameter+lineLength)/2)
        
        leftLinePath.move(to: leftUPoint)
        leftLinePath.addLine(to: leftDPoint)
        
        let leftLineLayer = CAShapeLayer()
        leftLineLayer.frame = bounds
        leftLineLayer.path = leftLinePath.cgPath
        leftLineLayer.lineWidth = lineWidth
        leftLineLayer.strokeColor = strokeColor.cgColor
        leftLineLayer.lineCap = kCALineCapRound
        
        containerLayer.addSublayer(leftLineLayer)
        
        rightLineALayer = CAShapeLayer()
        
        let xSpace = lineLength * 0.8
        let rightOx = (diameter+lineSpace)/2
        
        let playAPath = UIBezierPath()
        playAPath.move(to: leftUPoint)
        playAPath.addLine(to: CGPoint(x: leftUPoint.x+xSpace, y: diameter/2))
        
        let pauseAPath = UIBezierPath()
        pauseAPath.move(to: CGPoint(x: rightOx, y: leftUPoint.y))
        pauseAPath.addLine(to: CGPoint(x: rightOx, y: diameter/2))
        
        let playBPath = UIBezierPath()
        playBPath.move(to: leftDPoint)
        playBPath.addLine(to: CGPoint(x: leftDPoint.x+xSpace, y: diameter/2))
        
        let pauseBPath = UIBezierPath()
        pauseBPath.move(to: CGPoint(x: rightOx, y: leftDPoint.y))
        pauseBPath.addLine(to: CGPoint(x: rightOx, y: diameter/2))
        
        rightLinePaths = [playAPath.cgPath, playBPath.cgPath, pauseAPath.cgPath, pauseBPath.cgPath]
        
        rightLineALayer = CAShapeLayer()
        rightLineALayer.frame = bounds
        rightLineALayer.path = showPlay ? playAPath.cgPath : pauseAPath.cgPath
        rightLineALayer.lineWidth = lineWidth
        rightLineALayer.strokeColor = strokeColor.cgColor
        rightLineALayer.lineCap = kCALineCapRound
        
        containerLayer.addSublayer(rightLineALayer)
        
        rightLineBLayer = CAShapeLayer()
        rightLineBLayer.frame = bounds
        rightLineBLayer.path = showPlay ? playBPath.cgPath : pauseBPath.cgPath
        rightLineBLayer.lineWidth = lineWidth
        rightLineBLayer.strokeColor = strokeColor.cgColor
        rightLineBLayer.lineCap = kCALineCapRound
        
        containerLayer.addSublayer(rightLineBLayer)
    }
    
    override var isHighlighted: Bool {
        didSet {            
            if !isHighlighted && isTouchInside {
                ThrottleTimer.throttle(interval: 0.6, identifier: "play_button_animation") { [weak self] in
                    self?.showStateChangeAnimation()
                }
            }
        }
    }
    
    override var state: UIControlState {
        get {
            if super.state == .highlighted {
                showContainerScaleAnimation(tracking: true)
            } else if super.state == .normal {
                showContainerScaleAnimation(tracking: false)
            }
            return super.state
        }
    }
    
    fileprivate func showContainerScaleAnimation(tracking: Bool) {
        let transform = tracking ? CATransform3DMakeScale(0.88, 0.88, 1) : CATransform3DIdentity
        
        containerLayer.transform = transform
        
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
        animation.toValue = tracking ? transform : CATransform3DIdentity
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        containerLayer.add(animation, forKey: "containerScale")
    }
    
    fileprivate func showStateChangeAnimation() {
        showPlay = !showPlay
        
        tapHandler?(showPlay)
        
        let aPath = showPlay ? rightLinePaths[0] : rightLinePaths[2]
        let bPath = showPlay ? rightLinePaths[1] : rightLinePaths[3]
        
        let aAnim = CASpringAnimation(keyPath: #keyPath(CAShapeLayer.path))
        aAnim.fromValue = rightLineALayer.path!
        rightLineALayer.path = aPath
        aAnim.toValue = aPath
        aAnim.initialVelocity = 0.2
        aAnim.duration = 0.6
        rightLineALayer.add(aAnim, forKey: "rightLineA")
        
        let bAnim = CASpringAnimation(keyPath: #keyPath(CAShapeLayer.path))
        bAnim.fromValue = rightLineBLayer.path!
        rightLineBLayer.path = bPath
        bAnim.toValue = bPath
        bAnim.initialVelocity = 0.2
        bAnim.duration = 0.6
        rightLineBLayer.add(bAnim, forKey: "rightLineB")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
