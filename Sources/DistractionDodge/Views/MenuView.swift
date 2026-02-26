import SwiftUI

struct MenuView: View {
    @Binding var config: GameConfig
    let onPlay: () -> Void

    @ObservedObject private var progress = PlayerProgress.shared

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                floatingShapes(geo: geo)

                VStack(spacing: 0) {
                    Spacer()

                    // Title
                    VStack(spacing: 6) {
                        Text("🥷")
                            .font(.system(size: 80))
                        Text("Distraction Dodge")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Tap the target. Ignore the rest.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    Spacer().frame(height: 32)

                    // Duration picker
                    pickerSection(
                        icon: "timer", label: "Session Length",
                        items: GameDuration.allCases,
                        selected: config.duration,
                        title: { $0.label },
                        subtitle: { $0.subtitle },
                        select: { config.duration = $0 }
                    )
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 16)

                    // Difficulty picker
                    pickerSection(
                        icon: "speedometer", label: "Difficulty",
                        items: GameDifficulty.allCases,
                        selected: config.difficulty,
                        title: { $0.label },
                        subtitle: { _ in nil },
                        select: { config.difficulty = $0 }
                    )
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 24)

                    // Stats
                    statsRow
                        .padding(.horizontal, 28)

                    Spacer().frame(height: 28)

                    // Play
                    Button(action: onPlay) {
                        Text("Focus Up!")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: .green.opacity(0.5), radius: 16, y: 6)
                    }
                    .padding(.horizontal, 28)

                    Spacer()
                }
            }
        }
    }

    // MARK: - Sub-views

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.05, blue: 0.18),
                Color(red: 0.07, green: 0.03, blue: 0.24)
            ],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func floatingShapes(geo: GeometryProxy) -> some View {
        ForEach(menuFloaters, id: \.id) { f in
            FloatingShapeView(floater: f, height: geo.size.height)
        }
    }

    private func pickerSection<T: Hashable>(
        icon: String, label: String,
        items: [T], selected: T,
        title: @escaping (T) -> String, subtitle: @escaping (T) -> String?,
        select: @escaping (T) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.leading, 4)

            HStack(spacing: 10) {
                ForEach(items, id: \.self) { item in
                    PickerButton(
                        title: title(item),
                        subtitle: subtitle(item),
                        isSelected: selected == item
                    ) { select(item) }
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            StatItem(value: progress.bestScore(for: config), label: "Best",     emoji: "🏆")
            Divider().background(.white.opacity(0.2)).frame(height: 32)
            StatItem(value: progress.totalCorrectTaps,       label: "All Hits", emoji: "🎯")
            Divider().background(.white.opacity(0.2)).frame(height: 32)
            StatItem(value: progress.sessionsPlayed,         label: "Sessions", emoji: "🥷")
        }
        .padding(.vertical, 14)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private let menuFloaters: [FloatingShapeView.Floater] = (0..<20).map { _ in
        FloatingShapeView.Floater(
            id: UUID(),
            x: CGFloat.random(in: 0.04...0.96),
            startY: CGFloat.random(in: 0.1...1.1),
            size: CGFloat.random(in: 14...44),
            kind: ShapeKind.allCases.randomElement()!,
            duration: Double.random(in: 6...13),
            delay: Double.random(in: 0...8)
        )
    }
}

// MARK: - PickerButton

private struct PickerButton: View {
    let title:      String
    let subtitle:   String?
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold, design: .rounded))
                if let sub = subtitle {
                    Text(sub).font(.system(size: 12, weight: .medium, design: .rounded)).opacity(0.75)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.07))
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.white.opacity(0.5) : .clear, lineWidth: 1.5))
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - StatItem

private struct StatItem: View {
    let value: Int
    let label: String
    let emoji: String

    var body: some View {
        VStack(spacing: 3) {
            Text(emoji).font(.system(size: 18))
            Text("\(value)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Floating shape decoration

struct FloatingShapeView: View {
    struct Floater: Sendable {
        let id:       UUID
        let x:        CGFloat
        let startY:   CGFloat
        let size:     CGFloat
        let kind:     ShapeKind
        let duration: Double
        let delay:    Double
    }

    let floater: Floater
    let height:  CGFloat

    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double  = 0

    var body: some View {
        GeometryReader { geo in
            shapeView
                .frame(width: floater.size, height: floater.size)
                .position(
                    x: geo.size.width * floater.x,
                    y: floater.startY * height + offsetY
                )
                .opacity(opacity)
                .onAppear {
                    withAnimation(.linear(duration: floater.duration).repeatForever(autoreverses: false).delay(floater.delay)) {
                        offsetY = -height * 1.35
                    }
                    withAnimation(.easeIn(duration: 0.9).delay(floater.delay)) { opacity = 1 }
                }
        }
    }

    @ViewBuilder
    private var shapeView: some View {
        switch floater.kind {
        case .circle:
            Circle().stroke(.white.opacity(0.15), lineWidth: 1.5)
        case .square:
            RoundedRectangle(cornerRadius: floater.size * 0.15).stroke(.white.opacity(0.15), lineWidth: 1.5)
        case .triangle:
            Triangle().stroke(.white.opacity(0.15), lineWidth: 1.5)
        case .diamond:
            Diamond().stroke(.white.opacity(0.15), lineWidth: 1.5)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
        }
    }
}
