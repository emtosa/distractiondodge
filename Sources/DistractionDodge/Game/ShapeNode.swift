import SpriteKit
import UIKit

// MARK: - ShapeNode

/// A single gameplay shape — either the target or a decoy.
final class ShapeNode: SKNode {

    let kind:     ShapeKind
    let isTarget: Bool

    private let shapeLayer: SKShapeNode
    private let size: CGFloat

    static let defaultSize: CGFloat = 52

    init(kind: ShapeKind, isTarget: Bool, size: CGFloat = ShapeNode.defaultSize) {
        self.kind     = kind
        self.isTarget = isTarget
        self.size     = size

        shapeLayer = SKShapeNode(path: ShapeNode.path(for: kind, size: size))
        shapeLayer.lineWidth = 3

        if isTarget {
            shapeLayer.fillColor   = SKColor.systemGreen.withAlphaComponent(0.25)
            shapeLayer.strokeColor = SKColor.systemGreen
        } else {
            let hue = CGFloat.random(in: 0...1)
            let color = UIColor(hue: hue, saturation: 0.75, brightness: 0.90, alpha: 1)
            shapeLayer.fillColor   = SKColor(cgColor: color.cgColor).withAlphaComponent(0.18)
            shapeLayer.strokeColor = SKColor(cgColor: color.cgColor)
        }

        super.init()
        addChild(shapeLayer)

        // Use circle body for all shapes — reliable, no crash risk with complex paths
        physicsBody = SKPhysicsBody(circleOfRadius: size / 2)
        physicsBody?.isDynamic        = false
        physicsBody?.affectedByGravity = false
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Path factory

    static func path(for kind: ShapeKind, size: CGFloat) -> CGPath {
        let half = size / 2
        switch kind {
        case .circle:
            return CGPath(ellipseIn: CGRect(x: -half, y: -half, width: size, height: size), transform: nil)

        case .square:
            let r = size * 0.15
            return UIBezierPath(roundedRect: CGRect(x: -half, y: -half, width: size, height: size),
                                cornerRadius: r).cgPath

        case .triangle:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: half))
            path.addLine(to: CGPoint(x: half, y: -half))
            path.addLine(to: CGPoint(x: -half, y: -half))
            path.closeSubpath()
            return path

        case .diamond:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: half))
            path.addLine(to: CGPoint(x: half, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -half))
            path.addLine(to: CGPoint(x: -half, y: 0))
            path.closeSubpath()
            return path
        }
    }

    // MARK: - Animations

    func animateIn() {
        alpha = 0
        setScale(0.3)
        run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.22)
        ]))
    }

    func animatePop(correct: Bool, completion: @escaping () -> Void) {
        removeAllActions()
        let color: SKColor = correct ? .systemGreen : .systemRed
        shapeLayer.strokeColor = color
        shapeLayer.fillColor   = color.withAlphaComponent(0.35)

        run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: correct ? 1.6 : 0.4, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.18)
            ]),
            SKAction.removeFromParent(),
            SKAction.run(completion)
        ]))
    }

    func startLifespanAnimation(duration: TimeInterval) {
        // Pulse shrink to signal expiry
        run(SKAction.sequence([
            SKAction.wait(forDuration: duration * 0.55),
            SKAction.group([
                SKAction.scale(to: 0.05, duration: duration * 0.45),
                SKAction.fadeOut(withDuration: duration * 0.45)
            ]),
            SKAction.removeFromParent()
        ]), withKey: "lifespan")
    }
}
