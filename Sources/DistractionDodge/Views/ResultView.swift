import SwiftUI

struct ResultView: View {
    let score:       Int
    let accuracy:    Double   // 0–1
    let isNewBest:   Bool
    let bestScore:   Int
    let config:      GameConfig
    let onPlayAgain: () -> Void
    let onMenu:      () -> Void

    @State private var showContent  = false
    @State private var starScales: [CGFloat] = [0, 0, 0]

    private var stars: Int { config.difficulty.stars(score: score, duration: config.duration) }

    private var accuracyText: String {
        let pct = Int((accuracy * 100).rounded())
        switch pct {
        case 90...: return "Pinpoint accuracy! 🧘"
        case 75...: return "Sharp focus! 😌"
        case 60...: return "Getting cleaner! 🙂"
        case 40...: return "Keep training! 😐"
        default:    return "Watch the shape! 😤"
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.18),
                    Color(red: 0.07, green: 0.03, blue: 0.24)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if isNewBest {
                    Text("🏆  NEW BEST!")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 22).padding(.vertical, 9)
                        .background(Color.yellow.opacity(0.18))
                        .clipShape(Capsule())
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.4)
                        .padding(.bottom, 18)
                }

                Text("\(score) 🎯")
                    .font(.system(size: 70, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(showContent ? 1 : 0)
                    .padding(.bottom, 8)

                Text("\(Int((accuracy * 100).rounded()))% accuracy")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(showContent ? 1 : 0)
                    .padding(.bottom, 20)

                // Stars
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { i in
                        Text(i < stars ? "⭐️" : "✩")
                            .font(.system(size: 50))
                            .foregroundStyle(i < stars ? .yellow : .white.opacity(0.25))
                            .scaleEffect(starScales[i])
                    }
                }
                .padding(.bottom, 22)

                Text(accuracyText)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .opacity(showContent ? 1 : 0)

                if !isNewBest && bestScore > 0 {
                    Text("Best: \(bestScore) 🎯")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 6)
                        .opacity(showContent ? 1 : 0)
                }

                Spacer()

                VStack(spacing: 16) {
                    Button(action: onPlayAgain) {
                        Label("Play Again", systemImage: "arrow.clockwise")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: .green.opacity(0.5), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 32)

                    Button(action: onMenu) {
                        Text("Change Mode")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                .opacity(showContent ? 1 : 0)
                .padding(.bottom, 48)
            }
        }
        .onAppear { animateIn() }
    }

    private func animateIn() {
        withAnimation(.spring(duration: 0.45)) { showContent = true }
        for i in 0..<stars {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.42 + Double(i) * 0.18)) {
                starScales[i] = 1
            }
        }
        for i in stars..<3 {
            withAnimation(.easeOut(duration: 0.3).delay(0.4 + Double(i) * 0.1)) {
                starScales[i] = 1
            }
        }
    }
}
