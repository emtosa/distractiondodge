import XCTest
import SwiftUI
@testable import DistractionDodge

// Generates App Store screenshots via SwiftUI ImageRenderer.
// Run: xcodebuild test -scheme DistractionDodge -only-testing:DistractionDodgeTests/ScreenshotTests

@MainActor
final class ScreenshotTests: XCTestCase {

    let outputDir: URL = {
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOTS_DIR"] {
            return URL(fileURLWithPath: dir)
        }
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("AppStore/screenshots/en-US")
    }()

    let sizes: [(width: CGFloat, height: CGFloat)] = [
        (1320, 2868),   // iPhone 16 Pro Max
        (1284, 2778),   // iPhone 14 Plus
        (2064, 2752)    // iPad Pro 13"
    ]

    func testGenerateScreenshots() throws {
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        for (w, h) in sizes {
            let label = "\(Int(w))x\(Int(h))"

            // 1 – Menu
            let menu = MenuView(config: .constant(GameConfig())) {}
                .frame(width: w, height: h)
            save(menu, name: "01-menu-\(label)")

            // 2 – In-game (mock state via static overlay)
            let gameplay = GameplayScreenshot(screenW: w, screenH: h)
                .frame(width: w, height: h)
            save(gameplay, name: "02-gameplay-\(label)")

            // 3 – Result
            let result = ResultView(
                score: 18, accuracy: 0.92, isNewBest: true,
                bestScore: 18, config: GameConfig(),
                onPlayAgain: {}, onMenu: {}
            )
            .frame(width: w, height: h)
            save(result, name: "03-result-\(label)")

            // 4 – Ninja meter explainer
            let ninja = NinjaExplainerView(w: w, h: h)
                .frame(width: w, height: h)
            save(ninja, name: "04-ninja-\(label)")
        }
    }

    private func save(_ view: some View, name: String) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        guard let uiImage = renderer.uiImage,
              let data = uiImage.jpegData(compressionQuality: 0.92) else {
            XCTFail("Render failed for \(name)"); return
        }
        let url = outputDir.appendingPathComponent("\(name).jpg")
        try? data.write(to: url)
        print("📸 \(url.lastPathComponent)")
    }
}

// MARK: - Static screenshot views

private struct GameplayScreenshot: View {
    let screenW: CGFloat
    let screenH: CGFloat

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.05, blue: 0.18).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: screenH * 0.06)
                Text("TAP THE:")
                    .font(.system(size: screenH * 0.018, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                Text("⭕️  Circle")
                    .font(.system(size: screenH * 0.055, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: screenW * 0.08) {
                    shapeCell("⭕️", isTarget: true,  size: screenW * 0.18)
                    shapeCell("🔺", isTarget: false, size: screenW * 0.18)
                    shapeCell("🟦", isTarget: false, size: screenW * 0.18)
                }
                Spacer()
                Text("🧘  ZEN FOCUS").font(.system(size: screenH * 0.03, weight: .heavy, design: .rounded)).foregroundStyle(.green)
                Spacer().frame(height: screenH * 0.06)
            }
        }
    }

    private func shapeCell(_ emoji: String, isTarget: Bool, size: CGFloat) -> some View {
        Text(emoji).font(.system(size: size))
            .frame(width: size * 1.4, height: size * 1.4)
            .background(isTarget ? Color.green.opacity(0.2) : Color.white.opacity(0.06))
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(isTarget ? Color.green.opacity(0.6) : Color.white.opacity(0.2), lineWidth: 2))
    }
}

private struct NinjaExplainerView: View {
    let w: CGFloat, h: CGFloat

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.05, blue: 0.18).ignoresSafeArea()
            VStack(spacing: h * 0.025) {
                Spacer()
                Text("Focus Ninja Meter").font(.system(size: h * 0.038, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                ForEach(["😤 FRANTIC", "😐 DISTRACTED", "🙂 STEADY", "😌 CALM", "🧘 ZEN FOCUS"], id: \.self) { t in
                    Text(t).font(.system(size: h * 0.025, weight: .semibold, design: .rounded)).foregroundStyle(.white.opacity(0.85))
                }
                Text("Train your brain, one tap at a time.")
                    .font(.system(size: h * 0.022, design: .rounded)).foregroundStyle(.white.opacity(0.5))
                Spacer()
            }
        }
    }
}
