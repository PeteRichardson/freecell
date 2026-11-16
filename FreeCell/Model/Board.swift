import Foundation

/// A place on the board that holds cards.
enum Pile: Hashable, Sendable {
    case freeCell(Int)
    case foundation(Int)
    case cascade(Int)
}

/// Moves the last `count` cards of `from` onto `to`.
struct Move: Hashable, Sendable {
    var from: Pile
    var to: Pile
    var count: Int = 1
}

enum MoveError: Error, Equatable {
    case samePile
    case noCards
    case notASequence
    case fromFoundation
    case onlyOneCard
    case tooManyCards(max: Int)
    case notAllowed

    var message: String {
        switch self {
        case .samePile, .noCards: ""
        case .notASequence: "Those cards are not in sequence."
        case .fromFoundation: "Cards on a foundation stay there."
        case .onlyOneCard: "Only one card at a time can go there."
        case .tooManyCards(let max):
            "Not enough free cells or empty columns. You can move \(max) card\(max == 1 ? "" : "s") now."
        case .notAllowed: "That move is not allowed."
        }
    }
}

/// The FreeCell rules. A value type, so a copy of the board is an undo step.
struct Board: Equatable, Sendable {
    static let freeCellCount = 4
    static let foundationCount = 4
    static let cascadeCount = 8

    var freeCells: [Card?] = Array(repeating: nil, count: freeCellCount)
    var foundations: [[Card]] = Array(repeating: [], count: foundationCount)
    var cascades: [[Card]] = Array(repeating: [], count: cascadeCount)

    var isWon: Bool { foundations.allSatisfy { $0.count == 13 } }
    var emptyFreeCellCount: Int { freeCells.filter { $0 == nil }.count }
    var emptyCascadeCount: Int { cascades.filter(\.isEmpty).count }

    func cards(in pile: Pile) -> [Card] {
        switch pile {
        case .freeCell(let i): freeCells[i].map { [$0] } ?? []
        case .foundation(let i): foundations[i]
        case .cascade(let i): cascades[i]
        }
    }

    /// True if the cards of cascade `column` from `index` to the end go down in rank with alternate colours.
    func isSequence(cascade column: Int, from index: Int) -> Bool {
        let cards = cascades[column]
        guard index >= 0, index < cards.count else { return false }
        return zip(cards[index...], cards[(index + 1)...]).allSatisfy { upper, lower in lower.canStack(on: upper) }
    }

    /// The largest number of cards that can move as one unit (a "supermove").
    func maxMovableCards(toEmptyCascade: Bool) -> Int {
        let emptyCascades = max(0, emptyCascadeCount - (toEmptyCascade ? 1 : 0))
        return (emptyFreeCellCount + 1) << emptyCascades
    }

    /// The foundation that takes `card` next, if one does.
    func foundationIndex(accepting card: Card) -> Int? {
        if card.rank == 1 { return foundations.firstIndex(where: \.isEmpty) }
        return foundations.firstIndex { $0.last?.suit == card.suit && $0.last?.rank == card.rank - 1 }
    }

    func foundationRank(of suit: Suit) -> Int {
        foundations.first { $0.first?.suit == suit }?.count ?? 0
    }

    func validate(_ move: Move) -> MoveError? {
        guard move.from != move.to else { return .samePile }
        let source = cards(in: move.from)
        guard move.count >= 1, move.count <= source.count else { return .noCards }

        switch move.from {
        case .foundation: return .fromFoundation
        case .freeCell: break
        case .cascade(let column):
            guard isSequence(cascade: column, from: source.count - move.count) else { return .notASequence }
        }

        let moving = source[source.count - move.count]
        switch move.to {
        case .freeCell(let i):
            guard move.count == 1 else { return .onlyOneCard }
            return freeCells[i] == nil ? nil : .notAllowed

        case .foundation(let i):
            guard move.count == 1 else { return .onlyOneCard }
            let accepts = foundations[i].last.map { $0.suit == moving.suit && $0.rank == moving.rank - 1 }
                ?? (moving.rank == 1)
            return accepts ? nil : .notAllowed

        case .cascade(let i):
            let target = cascades[i]
            if let top = target.last, !moving.canStack(on: top) { return .notAllowed }
            let limit = maxMovableCards(toEmptyCascade: target.isEmpty)
            return move.count <= limit ? nil : .tooManyCards(max: limit)
        }
    }

    /// Applies a move. The caller must first make sure that `validate` returns nil.
    mutating func apply(_ move: Move) {
        let moving: [Card]
        switch move.from {
        case .freeCell(let i):
            moving = [freeCells[i]!]
            freeCells[i] = nil
        case .foundation(let i):
            moving = Array(foundations[i].suffix(move.count))
            foundations[i].removeLast(move.count)
        case .cascade(let i):
            moving = Array(cascades[i].suffix(move.count))
            cascades[i].removeLast(move.count)
        }
        switch move.to {
        case .freeCell(let i): freeCells[i] = moving[0]
        case .foundation(let i): foundations[i].append(contentsOf: moving)
        case .cascade(let i): cascades[i].append(contentsOf: moving)
        }
    }

    /// The best legal move for the last `count` cards of `pile`, for a tap on a card.
    /// The order is: foundation, a column with cards, an empty column, a free cell.
    func bestMove(from pile: Pile, count: Int) -> Move? {
        var targets: [Pile] = []
        if count == 1, let card = cards(in: pile).last, let f = foundationIndex(accepting: card) {
            targets.append(.foundation(f))
        }
        let columns = cascades.indices.filter { .cascade($0) != pile }
        targets += columns.filter { !cascades[$0].isEmpty }.map { .cascade($0) }
        // Moving a whole column to an empty column does nothing useful.
        if count < cards(in: pile).count || pile.isFreeCell {
            targets += columns.filter { cascades[$0].isEmpty }.map { .cascade($0) }
        }
        if count == 1, !pile.isFreeCell {
            targets += freeCells.indices.filter { freeCells[$0] == nil }.map { .freeCell($0) }
        }
        return targets.lazy.map { Move(from: pile, to: $0, count: count) }.first { validate($0) == nil }
    }

    /// A move to a foundation of a card that no other card can need any more.
    /// A card is safe when both foundations of the opposite colour have reached one rank below it,
    /// because then no card that could go on it is left in play.
    func safeAutoplayMove() -> Move? {
        let sources = freeCells.indices.map { Pile.freeCell($0) } + cascades.indices.map { Pile.cascade($0) }
        for pile in sources {
            guard let card = cards(in: pile).last, let f = foundationIndex(accepting: card) else { continue }
            let opposite = Suit.allCases.filter { $0.isRed != card.isRed }
            if card.rank <= 2 || opposite.allSatisfy({ foundationRank(of: $0) >= card.rank - 1 }) {
                return Move(from: pile, to: .foundation(f))
            }
        }
        return nil
    }
}

extension Pile {
    var isFreeCell: Bool {
        if case .freeCell = self { true } else { false }
    }
}
