import Testing
import Foundation
@testable import DistractionDodge

// MARK: - NinjaCalmMeter tests

@Suite("NinjaCalmMeter")
struct NinjaCalmMeterTests {

    @Test("starts at 50 (neutral)")
    func initialValue() {
        let meter = NinjaCalmMeter()
        #expect(meter.value == 50)
        #expect(meter.tier == 2)
    }

    @Test("hit increases value and correct tier")
    func hitRaisesValue() {
        var meter = NinjaCalmMeter()
        meter.recordHit()
        meter.recordHit()
        meter.recordHit()
        #expect(meter.value == 74)
        #expect(meter.tier == 3)
    }

    @Test("wrong tap lowers value significantly")
    func wrongTapLowersValue() {
        var meter = NinjaCalmMeter()
        meter.recordWrongTap()
        meter.recordWrongTap()
        meter.recordWrongTap()
        #expect(meter.value == 14)
        #expect(meter.tier == 0)
    }

    @Test("clamps at 0 and 100")
    func clamping() {
        var meter = NinjaCalmMeter()
        for _ in 0..<20 { meter.recordHit() }
        #expect(meter.value == 100)

        for _ in 0..<20 { meter.recordWrongTap() }
        #expect(meter.value == 0)
    }
}

// MARK: - GameConfig / ShapeKind tests

@Suite("ShapeKind")
struct ShapeKindTests {

    @Test("decoys excludes self")
    func decoysExcludesSelf() {
        for kind in ShapeKind.allCases {
            let decoys = kind.decoys()
            #expect(!decoys.contains(kind))
            #expect(decoys.count == 3)
        }
    }
}

// MARK: - GameDifficulty tests

@Suite("GameDifficulty")
struct GameDifficultyTests {

    @Test("spawn interval decreases over time")
    func spawnIntervalRamps() {
        let early = GameDifficulty.normal.spawnInterval(elapsed: 0,  totalDuration: 60)
        let late  = GameDifficulty.normal.spawnInterval(elapsed: 55, totalDuration: 60)
        #expect(late < early)
    }

    @Test("stars awarded correctly")
    func starsThresholds() {
        // score below all thresholds → 0 stars
        #expect(GameDifficulty.normal.stars(score: 0,  duration: .classic) == 0)
        // well above three-star threshold
        #expect(GameDifficulty.normal.stars(score: 100, duration: .classic) == 3)
    }
}

// MARK: - PlayerProgress tests

@Suite("PlayerProgress")
struct PlayerProgressTests {

    @Test("records session and updates totals")
    @MainActor func recordSession() {
        let suite    = UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        let progress = PlayerProgress(defaults: suite)
        let config   = GameConfig()

        let isNew = progress.record(score: 10, config: config)
        #expect(isNew == true)
        #expect(progress.bestScore(for: config) == 10)
        #expect(progress.sessionsPlayed == 1)
        #expect(progress.totalCorrectTaps == 10)
    }

    @Test("new best returns true only when score is higher")
    @MainActor func newBestFlag() {
        let suite    = UserDefaults(suiteName: "test_\(UUID().uuidString)")!
        let progress = PlayerProgress(defaults: suite)
        let config   = GameConfig()

        let first  = progress.record(score: 5,  config: config)
        let second = progress.record(score: 3,  config: config)
        let third  = progress.record(score: 10, config: config)

        #expect(first  == true)
        #expect(second == false)
        #expect(third  == true)
    }
}
