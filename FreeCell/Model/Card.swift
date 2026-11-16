import Foundation

/// The four suits, in the order the Microsoft deal algorithm uses.
enum Suit: Int, CaseIterable, Sendable {
    case clubs, diamonds, hearts, spades

    var isRed: Bool { self == .diamonds || self == .hearts }

    var name: String {
        switch self {
        case .clubs: "clubs"
        case .diamonds: "diamonds"
        case .hearts: "hearts"
        case .spades: "spades"
        }
    }
}

struct Card: Hashable, Identifiable, Sendable, CustomStringConvertible {
    /// 1 = ace, 11 = jack, 12 = queen, 13 = king.
    let rank: Int
    let suit: Suit

    var id: Int { suit.rawValue * 13 + rank - 1 }
    var isRed: Bool { suit.isRed }

    var rankName: String {
        switch rank {
        case 1: "ace"
        case 11: "jack"
        case 12: "queen"
        case 13: "king"
        default: String(rank)
        }
    }

    /// Name of the image in the asset catalog, for example "queen_of_hearts".
    var imageName: String { "\(rankName)_of_\(suit.name)" }

    var description: String { "\(rankName) of \(suit.name)" }

    /// True if this card can go on `other` in a cascade: one rank lower and the opposite colour.
    func canStack(on other: Card) -> Bool {
        rank == other.rank - 1 && isRed != other.isRed
    }
}
