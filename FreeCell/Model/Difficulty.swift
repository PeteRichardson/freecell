import Foundation

/// How hard a deal is. Each deal has one fixed difficulty, from the solver effort it needs.
/// See docs/adr/0001-rate-deals-offline-by-solver-effort.md.
enum Difficulty: String, CaseIterable, Identifiable {
    case easy, medium, hard

    var id: Self { self }

    var name: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }

    /// The letter for this difficulty in DealDifficulty.txt.
    fileprivate var letter: Character {
        switch self {
        case .easy: "E"
        case .medium: "M"
        case .hard: "H"
        }
    }
}

extension Deal {
    /// The difficulty of each deal, made by scripts/rate_deals.sh. Character n - 1 is for deal n.
    private static let ratings: [Character] = {
        guard let url = Bundle.main.url(forResource: "DealDifficulty", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { fatalError("DealDifficulty.txt is missing from the app") }
        return Array(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }()

    private static let numbersByDifficulty: [Difficulty: [Int]] = Dictionary(
        grouping: range.filter { difficulty(of: $0) != nil },
        by: { difficulty(of: $0)! }
    )

    /// The difficulty of a deal, or nil for a deal that has no rating (#11982, or a number out of range).
    static func difficulty(of number: Int) -> Difficulty? {
        guard range.contains(number), number <= ratings.count else { return nil }
        let letter = ratings[number - 1]
        return Difficulty.allCases.first { $0.letter == letter }
    }

    /// The numbers of all deals with this difficulty.
    static func numbers(of difficulty: Difficulty) -> [Int] {
        numbersByDifficulty[difficulty] ?? []
    }

    static func randomNumber(difficulty: Difficulty) -> Int {
        numbers(of: difficulty).randomElement()!
    }
}
