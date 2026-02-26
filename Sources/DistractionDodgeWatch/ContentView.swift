import SwiftUI

struct ContentView: View {
    @AppStorage("dd_watch_best") private var bestScore: Int = 0
    @AppStorage("dd_watch_sessions") private var sessions: Int = 0
    private let calmLevels = ["😤","😐","🙂","😌","🧘"]

    var body: some View {
        VStack(spacing: 8) {
            Text("🥷 Focus Ninja")
                .font(.headline)
            Text(calmLevels[min(sessions / 5, 4)])
                .font(.system(size: 40))
            HStack {
                Label("\(sessions)", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                Label("\(bestScore)", systemImage: "star.fill")
                    .foregroundStyle(.yellow)
            }
            .font(.caption)
        }
        .padding()
    }
}

#Preview { ContentView() }
