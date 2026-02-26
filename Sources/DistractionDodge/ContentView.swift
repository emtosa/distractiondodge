import SwiftUI

enum AppScreen {
    case menu, game, result(score: Int, accuracy: Double, isNewBest: Bool)
}

struct ContentView: View {
    @State private var screen: AppScreen = .menu
    @State private var config = GameConfig()

    var body: some View {
        switch screen {
        case .menu:
            MenuView(config: $config) {
                screen = .game
            }
        case .game:
            GameView(config: config) { score, accuracy, isNewBest in
                screen = .result(score: score, accuracy: accuracy, isNewBest: isNewBest)
            }
        case .result(let score, let accuracy, let isNewBest):
            ResultView(
                score: score,
                accuracy: accuracy,
                isNewBest: isNewBest,
                bestScore: PlayerProgress.shared.bestScore(for: config),
                config: config,
                onPlayAgain: { screen = .game },
                onMenu: { screen = .menu }
            )
        }
    }
}
