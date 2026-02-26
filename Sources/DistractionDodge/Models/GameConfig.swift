import Foundation

// MARK: - Shape Kind

/// The four distinguishable shapes used in gameplay.
enum ShapeKind: Int, CaseIterable, Hashable {
    case circle   = 0
    case square   = 1
    case triangle = 2
    case diamond  = 3

    var emoji: String {
        switch self {
        case .circle:   return "⭕️"
        case .square:   return "🟦"
        case .triangle: return "🔺"
        case .diamond:  return "💠"
        }
    }

    var label: String {
        switch self {
        case .circle:   return "Circle"
        case .square:   return "Square"
        case .triangle: return "Triangle"
        case .diamond:  return "Diamond"
        }
    }

    /// Returns all cases except self (i.e. the decoy shapes for a given target).
    func decoys() -> [ShapeKind] {
        ShapeKind.allCases.filter { $0 != self }
    }
}

// MARK: - Difficulty

enum GameDifficulty: Int, CaseIterable, Hashable {
    case easy   = 0
    case normal = 1
    case hard   = 2

    var label: String {
        switch self {
        case .easy:   return "Easy 🌱"
        case .normal: return "Normal ⭐️"
        case .hard:   return "Hard 🔥"
        }
    }

    /// Starting spawn interval (seconds between shapes)
    var initialSpawnInterval: Double {
        switch self {
        case .easy:   return 1.8
        case .normal: return 1.3
        case .hard:   return 0.9
        }
    }

    var spawnRamp: Double {
        switch self {
        case .easy:   return 0.6
        case .normal: return 0.9
        case .hard:   return 0.5
        }
    }

    var minSpawnInterval: Double {
        switch self {
        case .easy:   return 0.9
        case .normal: return 0.5
        case .hard:   return 0.3
        }
    }

    var initialLifespan: Double {
        switch self {
        case .easy:   return 3.2
        case .normal: return 2.5
        case .hard:   return 1.8
        }
    }

    var lifespanRamp: Double {
        switch self {
        case .easy:   return 0.8
        case .normal: return 1.4
        case .hard:   return 0.6
        }
    }

    var minLifespan: Double {
        switch self {
        case .easy:   return 2.0
        case .normal: return 1.0
        case .hard:   return 0.8
        }
    }

    /// How many decoys appear per target at each stage
    func decoyCount(elapsed: TimeInterval, totalDuration: TimeInterval) -> Int {
        let progress = elapsed / totalDuration
        switch self {
        case .easy:   return progress < 0.5 ? 1 : 2
        case .normal: return progress < 0.33 ? 1 : progress < 0.66 ? 2 : 3
        case .hard:   return progress < 0.25 ? 2 : 3
        }
    }

    func spawnInterval(elapsed: TimeInterval, totalDuration: TimeInterval) -> TimeInterval {
        let progress = elapsed / totalDuration
        return max(minSpawnInterval, initialSpawnInterval - progress * spawnRamp)
    }

    func lifespan(elapsed: TimeInterval, totalDuration: TimeInterval) -> TimeInterval {
        let progress = min(1.0, elapsed / totalDuration)
        return max(minLifespan, initialLifespan - progress * lifespanRamp)
    }

    func starThresholds(duration: GameDuration) -> (one: Int, two: Int, three: Int) {
        let base = duration.rawValue / 10
        switch self {
        case .easy:   return (base * 1, base * 2, base * 4)
        case .normal: return (base * 2, base * 4, base * 7)
        case .hard:   return (base * 3, base * 6, base * 10)
        }
    }

    func stars(score: Int, duration: GameDuration) -> Int {
        let t = starThresholds(duration: duration)
        switch score {
        case t.three...: return 3
        case t.two...:   return 2
        case t.one...:   return 1
        default:         return 0
        }
    }
}

// MARK: - Duration

enum GameDuration: Int, CaseIterable, Hashable {
    case quick    = 30
    case classic  = 60
    case marathon = 90

    var label: String {
        switch self {
        case .quick:    return "Quick"
        case .classic:  return "Classic"
        case .marathon: return "Marathon"
        }
    }

    var subtitle: String {
        switch self {
        case .quick:    return "30s ⚡️"
        case .classic:  return "60s 🎯"
        case .marathon: return "90s 🏃"
        }
    }
}

// MARK: - Config

struct GameConfig: Equatable {
    var duration:   GameDuration   = .classic
    var difficulty: GameDifficulty = .normal
    var lives: Int = 3
}

// MARK: - Ninja Calm Meter

/// Represents the focus ninja's current calm state based on session accuracy.
struct NinjaCalmMeter {
    private(set) var value: Double = 50  // 0–100

    mutating func recordHit()  { value = min(100, value + 8) }
    mutating func recordMiss() { value = max(0,   value - 5) }
    mutating func recordWrongTap() { value = max(0, value - 12) }

    var tier: Int {
        switch value {
        case 80...: return 4   // zen
        case 60...: return 3   // calm
        case 40...: return 2   // neutral
        case 20...: return 1   // distracted
        default:    return 0   // frantic
        }
    }

    var emoji: String {
        switch tier {
        case 4: return "🧘"
        case 3: return "😌"
        case 2: return "🙂"
        case 1: return "😐"
        default: return "😤"
        }
    }

    var label: String {
        switch tier {
        case 4: return "ZEN FOCUS"
        case 3: return "CALM"
        case 2: return "STEADY"
        case 1: return "DISTRACTED"
        default: return "FRANTIC"
        }
    }

    var color: String {
        switch tier {
        case 4: return "systemGreen"
        case 3: return "systemMint"
        case 2: return "systemYellow"
        case 1: return "systemOrange"
        default: return "systemRed"
        }
    }
}
