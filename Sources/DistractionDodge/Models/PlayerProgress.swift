import Foundation

@MainActor
final class PlayerProgress: ObservableObject {

    static let shared = PlayerProgress()

    private let defaults: UserDefaults

    @Published private(set) var totalCorrectTaps: Int
    @Published private(set) var sessionsPlayed: Int

    private init() {
        self.defaults      = .standard
        totalCorrectTaps   = defaults.integer(forKey: "totalCorrectTaps")
        sessionsPlayed     = defaults.integer(forKey: "sessionsPlayed")
    }

    init(defaults: UserDefaults) {
        self.defaults      = defaults
        totalCorrectTaps   = defaults.integer(forKey: "totalCorrectTaps")
        sessionsPlayed     = defaults.integer(forKey: "sessionsPlayed")
    }

    func bestScore(for config: GameConfig) -> Int {
        defaults.integer(forKey: bestScoreKey(for: config))
    }

    /// Records a finished session. Returns `true` if a new best was set.
    @discardableResult
    func record(score: Int, config: GameConfig) -> Bool {
        totalCorrectTaps += score
        sessionsPlayed   += 1
        defaults.set(totalCorrectTaps, forKey: "totalCorrectTaps")
        defaults.set(sessionsPlayed,   forKey: "sessionsPlayed")

        let key      = bestScoreKey(for: config)
        let previous = defaults.integer(forKey: key)
        let isNew    = score > previous
        if isNew { defaults.set(score, forKey: key) }
        return isNew
    }

    private func bestScoreKey(for config: GameConfig) -> String {
        "bs_dur\(config.duration.rawValue)_dif\(config.difficulty.rawValue)"
    }
}
