import SpriteKit
import UIKit
import AudioToolbox

// MARK: - GameScene

final class GameScene: SKScene {

    // Set before presenting
    var config: GameConfig = GameConfig()
    var onGameOver: (@MainActor (Int, Double) -> Void)?   // (score, accuracy 0–1)

    // MARK: - State
    private var score        = 0
    private var wrongTaps    = 0
    private var totalTaps    = 0
    private var livesLeft    = 3
    private var gameOver     = false
    private var startTime:   TimeInterval = 0
    private var lastSpawnTime: TimeInterval = 0
    private var currentTarget: ShapeKind   = .circle
    private var ninja = NinjaCalmMeter()

    // MARK: - HUD nodes
    private var scoreLabel:  SKLabelNode!
    private var timerLabel:  SKLabelNode!
    private var targetLabel: SKLabelNode!
    private var ninjaLabel:  SKLabelNode!
    private var livesLabel:  SKLabelNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.03, green: 0.05, blue: 0.18, alpha: 1)
        livesLeft = config.lives
        currentTarget = ShapeKind.allCases.randomElement()!
        addStars()
        setupHUD()
    }

    private func addStars() {
        for _ in 0..<60 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...2.2))
            star.fillColor   = SKColor(white: 1, alpha: CGFloat.random(in: 0.06...0.22))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            addChild(star)
        }
    }

    private func setupHUD() {
        // "TAP THE:" instruction line
        let instructLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        instructLabel.fontSize   = 14
        instructLabel.fontColor  = SKColor.white.withAlphaComponent(0.55)
        instructLabel.position   = CGPoint(x: frame.midX, y: frame.maxY - 58)
        instructLabel.text       = "TAP THE:"
        instructLabel.zPosition  = 10
        addChild(instructLabel)

        // Target shape emoji
        targetLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        targetLabel.fontSize  = 42
        targetLabel.position  = CGPoint(x: frame.midX, y: frame.maxY - 108)
        targetLabel.zPosition = 10
        addChild(targetLabel)
        updateTargetLabel()

        // Score (top-right)
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize  = 28
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position  = CGPoint(x: frame.maxX - 20, y: frame.maxY - 68)
        scoreLabel.zPosition = 10
        scoreLabel.text      = "0"
        addChild(scoreLabel)

        // Timer (top-left)
        timerLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        timerLabel.fontSize  = 24
        timerLabel.fontColor = SKColor.systemYellow
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.position  = CGPoint(x: 20, y: frame.maxY - 68)
        timerLabel.zPosition = 10
        addChild(timerLabel)

        // Lives
        livesLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        livesLabel.fontSize  = 22
        livesLabel.fontColor = SKColor.systemRed
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.position  = CGPoint(x: 20, y: frame.maxY - 100)
        livesLabel.zPosition = 10
        addChild(livesLabel)
        updateLivesLabel()

        // Ninja calm meter (bottom)
        ninjaLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        ninjaLabel.fontSize  = 28
        ninjaLabel.fontColor = SKColor.systemGreen
        ninjaLabel.horizontalAlignmentMode = .center
        ninjaLabel.position  = CGPoint(x: frame.midX, y: 42)
        ninjaLabel.zPosition = 10
        addChild(ninjaLabel)
        updateNinjaLabel()
    }

    private func updateTargetLabel() {
        targetLabel.text = "\(currentTarget.emoji)  \(currentTarget.label)"
        targetLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    private func updateLivesLabel() {
        livesLabel.text = String(repeating: "❤️", count: max(0, livesLeft))
    }

    private func updateNinjaLabel() {
        ninjaLabel.text = "\(ninja.emoji)  \(ninja.label)"
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }

        if startTime == 0 { startTime = currentTime }

        let elapsed   = currentTime - startTime
        let remaining = max(0, Double(config.duration.rawValue) - elapsed)

        let secs = Int(remaining.rounded(.up))
        timerLabel.text      = "\(secs)s"
        timerLabel.fontColor = remaining <= 10 ? SKColor.systemRed : SKColor.systemYellow

        if remaining <= 0 || livesLeft <= 0 {
            triggerGameOver()
            return
        }

        let spawnInterval = config.difficulty.spawnInterval(elapsed: elapsed, totalDuration: Double(config.duration.rawValue))
        if currentTime - lastSpawnTime >= spawnInterval {
            spawnWave(elapsed: elapsed)
            lastSpawnTime = currentTime
        }
    }

    // MARK: - Spawning

    private func spawnWave(elapsed: TimeInterval) {
        let lifespan   = config.difficulty.lifespan(elapsed: elapsed, totalDuration: Double(config.duration.rawValue))
        let decoyCount = config.difficulty.decoyCount(elapsed: elapsed, totalDuration: Double(config.duration.rawValue))
        let decoys     = currentTarget.decoys().shuffled().prefix(decoyCount)

        var toSpawn: [(ShapeKind, Bool)] = [(currentTarget, true)]
        toSpawn += decoys.map { ($0, false) }

        for (kind, isTarget) in toSpawn {
            spawnShape(kind: kind, isTarget: isTarget, lifespan: lifespan)
        }
    }

    private func spawnShape(kind: ShapeKind, isTarget: Bool, lifespan: TimeInterval) {
        let node = ShapeNode(kind: kind, isTarget: isTarget)
        let margin: CGFloat = ShapeNode.defaultSize + 10
        let x = CGFloat.random(in: margin...(frame.maxX - margin))
        let y = CGFloat.random(in: (margin + 60)...(frame.maxY - margin - 140))
        node.position  = CGPoint(x: x, y: y)
        node.zPosition = 1
        addChild(node)
        node.animateIn()
        node.startLifespanAnimation(duration: lifespan)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver, let touch = touches.first else { return }
        let loc = touch.location(in: self)

        let hit = nodes(at: loc).compactMap { $0 as? ShapeNode }.first
            ?? nodes(at: loc).compactMap { $0.parent as? ShapeNode }.first

        if let node = hit {
            handleTap(node: node)
        }
        // Tapping empty space is a miss (no penalty — only wrong shape taps penalise)
    }

    private func handleTap(node: ShapeNode) {
        node.removeAction(forKey: "lifespan")
        totalTaps += 1

        if node.isTarget {
            score += 1
            ninja.recordHit()
            updateScoreLabel()
            showHitEffect(at: node.position, correct: true)
            provideHaptic(correct: true)
            node.animatePop(correct: true) { [weak self] in
                self?.rotateTarget()
            }
        } else {
            wrongTaps  += 1
            livesLeft  -= 1
            ninja.recordWrongTap()
            updateLivesLabel()
            showHitEffect(at: node.position, correct: false)
            provideHaptic(correct: false)
            shakeCamera()
            node.animatePop(correct: false) {}
            if livesLeft <= 0 { triggerGameOver() }
        }
        updateNinjaLabel()
    }

    private func rotateTarget() {
        guard !gameOver else { return }
        // Pick a new target that differs from current
        let others = ShapeKind.allCases.filter { $0 != currentTarget }
        currentTarget = others.randomElement()!
        updateTargetLabel()
    }

    // MARK: - HUD helpers

    private func updateScoreLabel() {
        scoreLabel.text = "\(score)"
        scoreLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.45, duration: 0.07),
            SKAction.scale(to: 1.0,  duration: 0.09)
        ]))
    }

    // MARK: - Effects

    private func showHitEffect(at position: CGPoint, correct: Bool) {
        let color: SKColor = correct ? .systemGreen : .systemRed
        for _ in 0..<8 {
            let r   = CGFloat.random(in: 4...9)
            let dot = SKShapeNode(circleOfRadius: r)
            dot.fillColor   = color
            dot.strokeColor = .clear
            dot.position    = position
            dot.zPosition   = 5
            addChild(dot)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist  = CGFloat.random(in: 25...65)
            let dest  = CGPoint(x: position.x + cos(angle) * dist,
                                y: position.y + sin(angle) * dist)
            dot.run(SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: dest,  duration: 0.28),
                    SKAction.fadeOut(withDuration: 0.28),
                    SKAction.scale(to: 0.1,  duration: 0.28)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func shakeCamera() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -8, y: 0, duration: 0.04),
            SKAction.moveBy(x: 16, y: 0, duration: 0.04),
            SKAction.moveBy(x: -8, y: 0, duration: 0.04)
        ])
        run(shake)
    }

    private func provideHaptic(correct: Bool) {
        if correct {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            AudioServicesPlaySystemSound(1057)
        } else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            AudioServicesPlaySystemSound(1053)
        }
    }

    // MARK: - Game Over

    private func triggerGameOver() {
        guard !gameOver else { return }
        gameOver = true
        removeAllActions()

        children.compactMap { $0 as? ShapeNode }.forEach {
            $0.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
        }

        let accuracy: Double = totalTaps > 0 ? Double(score) / Double(totalTaps) : 1.0

        // Big score display
        let finalLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        finalLabel.fontSize  = 52
        finalLabel.fontColor = SKColor.systemYellow
        finalLabel.horizontalAlignmentMode = .center
        finalLabel.position  = CGPoint(x: frame.midX, y: frame.midY + 20)
        finalLabel.text      = "\(score) 🎯"
        finalLabel.alpha     = 0
        finalLabel.zPosition = 20
        addChild(finalLabel)

        finalLabel.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            guard let self else { return }
            self.onGameOver?(self.score, accuracy)
        }
    }

    // MARK: - Test support
    #if DEBUG
    func simulateTap(on kind: ShapeKind, isTarget: Bool, at position: CGPoint) {
        let node = ShapeNode(kind: kind, isTarget: isTarget)
        node.position = position
        addChild(node)
        handleTap(node: node)
    }
    #endif
}
