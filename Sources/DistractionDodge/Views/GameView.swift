import SwiftUI
import SpriteKit

struct GameView: View {
    let config: GameConfig
    let onGameOver: (Int, Double, Bool) -> Void   // score, accuracy, isNewBest

    @State private var scene: GameScene?
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var voiceOverScore = 0
    @State private var voiceOverDodges = 0

    var body: some View {
        if voiceOverEnabled {
            voiceOverGameView
        } else {
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
    }

    /// Simplified accessible game mode: tap to dodge, score counter.
    private var voiceOverGameView: some View {
        VStack(spacing: 32) {
            Text("🎯 DistractionDodge")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            Text("Score: \(voiceOverScore)")
                .font(.title2.weight(.semibold))
                .accessibilityValue("\(voiceOverScore) points")

            Button {
                voiceOverDodges += 1
                voiceOverScore  += 10
            } label: {
                Label("Dodge!", systemImage: "arrow.left.arrow.right")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .accessibilityHint("Dodges a distraction and scores 10 points")

            Button {
                let accuracy = voiceOverDodges > 0 ? 1.0 : 0.0
                let isNew = PlayerProgress.shared.record(score: voiceOverScore, config: config)
                onGameOver(voiceOverScore, accuracy, isNew)
            } label: {
                Text("End game")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .contain)
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
