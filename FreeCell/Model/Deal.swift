import Foundation

/// Deals numbered games with the Microsoft FreeCell algorithm, so game numbers match other FreeCell programs.
enum Deal {
    static let range = 1...32000
    /// The one Microsoft deal in 1...32000 that nobody can solve.
    static let unsolvable = 11982

    static func board(number: Int) -> Board {
        var seed = UInt32(truncatingIfNeeded: number)
        func next() -> Int {
            seed = seed &* 214013 &+ 2531011
            return Int((seed >> 16) & 0x7fff)
        }

        // Card i of the starting deck is rank i / 4 in suit order clubs, diamonds, hearts, spades.
        var deck = (0..<52).map { Card(rank: $0 / 4 + 1, suit: Suit(rawValue: $0 % 4)!) }
        var board = Board()
        for i in 0..<52 {
            let left = 52 - i
            let j = next() % left
            board.cascades[i % Board.cascadeCount].append(deck[j])
            deck[j] = deck[left - 1]
        }
        return board
    }
}
