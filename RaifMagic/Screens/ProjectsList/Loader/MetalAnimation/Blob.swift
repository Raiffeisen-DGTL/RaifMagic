//
//  Blob.swift
//  RaifMagic
//
//  Created by SHUMAKOV Kirill on 25.06.2024.
//

import SwiftUI


final class BlobLayer: CAGradientLayer {

    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    init(color: Color) {
        super.init()
        self.type = .radial
        autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        setGradient(color: color)
        updateLocation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func animate(speed: CGFloat) {
        guard speed > 0 else { return }
        
        self.removeAllAnimations()
        let currentLayer = self.presentation() ?? self
        
        let position = randomPosition()
        let radius = randomRadius()
        
        let startPoint = makeAnimation(speed: speed)
        startPoint.keyPath = "startPoint"
        startPoint.fromValue = currentLayer.startPoint
        startPoint.toValue = position
        
        let endPoint = makeAnimation(speed: speed)
        let newEndPoint = position.moved(by: radius)
        endPoint.keyPath = "endPoint"
        endPoint.fromValue = currentLayer.endPoint
        endPoint.toValue = newEndPoint
        
        self.startPoint = position
        self.endPoint = newEndPoint
        
        let value = Float.random(in: 0.5...1)
        let opacity = makeAnimation(speed: speed)
        opacity.fromValue = self.opacity
        opacity.toValue = value
        
        self.opacity = value

        self.add(opacity, forKey: "opacity")
        self.add(startPoint, forKey: "startPoint")
        self.add(endPoint, forKey: "endPoint")
    }
    
    private func setGradient(color: Color) {
        self.colors = [
            NSColor(color).cgColor,
            NSColor(color).cgColor,
            NSColor(color.opacity(0.0)).cgColor
        ]
        self.locations = [0.0, 0.9, 1.0]
    }
    
    private func updateLocation() {
        // Center point
        let position = randomPosition()
        self.startPoint = position
        
        // Radius
        let radius = randomRadius()
        self.endPoint = position.moved(by: radius)
    }
    private func makeAnimation(speed: CGFloat) -> CASpringAnimation {
        let animation = CASpringAnimation()
        animation.mass = 10/speed
        animation.damping = 50
        animation.duration = 1/speed
        
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        return animation
    }
    
    private func randomPosition() -> CGPoint {
        return CGPoint(x: CGFloat.random(in: 0.0...1.0),
                       y: CGFloat.random(in: 0.0...1.0))
    }
    
    private func randomRadius() -> CGPoint {
        let size = CGFloat.random(in: 0.15...0.8)
        let viewRatio = frame.width/frame.height
        let ratio = max(viewRatio.isNaN ? 1 : viewRatio, 1)*CGFloat.random(in: 0.25...1.75)
        return CGPoint(
            x: size,
            y: size*ratio
        )
    }
}
extension CGPoint {

    func moved(by point: CGPoint = .init(x: 0.0, y: 0.0)) -> CGPoint {
        return CGPoint(x: self.x+point.x,
                       y: self.y+point.y)
    }
}
