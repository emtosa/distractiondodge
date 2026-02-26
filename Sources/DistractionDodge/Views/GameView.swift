import SwiftUI
import SpriteKit

struct GameView: View {
    let config: GameConfig
    let onGameOver: (Int, Double, Bool) -> Void   // score, accuracy, isNewBest

    @State private var scene: GameScene?

    var body: some View {
        Group {
            if let scene {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
        .onAppear { setupScene() }
    }

    private func setupScene() {
        let s = GameScene()
        s.config = config
        s.scaleMode = .resizeFill
        s.onGameOver = { score, accuracy in
            let isNew = PlayerProgress.shared.record(score: score, config: config)
            onGameOver(score, accuracy, isNew)
        }
        scene = s
    }
}
