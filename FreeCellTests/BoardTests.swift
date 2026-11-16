import Testing
@testable import FreeCell

private func card(_ text: String) -> Card {
    let suits: [Character: Suit] = ["C": .clubs, "D": .diamonds, "H": .hearts, "S": .spades]
    let ranks: [String: Int] = ["A": 1, "T": 10, "J": 11, "Q": 12, "K": 13]
    let rankText = String(text.dropLast())
    return Card(rank: ranks[rankText] ?? Int(rankText)!, suit: suits[text.last!]!)
}

private func cards(_ text: String) -> [Card] {
    text.split(separator: " ").map { card(String($0)) }
}

struct DealTests {
    @Test func microsoftGameOneMatchesKnownLayout() {
        // Rows of game #1, from the published Microsoft deal list.
        let rows = [
            "JD 2D 9H JC 5D 7H 7C 5H",
            "KD KC 9S 5S AD QC KH 3H",
            "2S KS 9D QD JS AS AH 3C",
            "4C 5C TS QH 4H AC 4D 7S",
            "3S TD 4S TH 8H 2C JH 7D",
            "6D 8S 8D QS 6C 3D 8C TC",
            "6S 9C 2H 6H",
        ].map(cards)
        let board = Deal.board(number: 1)
        for (rowIndex, row) in rows.enumerated() {
            for (column, expected) in row.enumerated() {
                #expect(board.cascades[column][rowIndex] == expected)
            }
        }
        #expect(board.cascades.map(\.count) == [7, 7, 7, 7, 6, 6, 6, 6])
    }

    @Test func dealHasEveryCardOnce() {
        let board = Deal.board(number: 12345)
        let ids = board.cascades.flatMap { $0 }.map(\.id)
        #expect(Set(ids) == Set(0..<52))
    }
}

struct MoveTests {
    @Test func cascadeAcceptsOnlyLowerRankOfOppositeColour() {
        var board = Board()
        board.cascades[0] = cards("8S")
        board.cascades[1] = cards("7H")
        board.cascades[2] = cards("7C")
        board.cascades[3] = cards("6H")
        #expect(board.validate(Move(from: .cascade(1), to: .cascade(0))) == nil)
        #expect(board.validate(Move(from: .cascade(2), to: .cascade(0))) == .notAllowed)
        #expect(board.validate(Move(from: .cascade(3), to: .cascade(0))) == .notAllowed)
    }

    @Test func foundationNeedsAceFirstThenSameSuitInOrder() {
        var board = Board()
        board.cascades[0] = cards("2H")
        board.cascades[1] = cards("AH")
        #expect(board.validate(Move(from: .cascade(0), to: .foundation(0))) == .notAllowed)
        #expect(board.validate(Move(from: .cascade(1), to: .foundation(0))) == nil)
        board.apply(Move(from: .cascade(1), to: .foundation(0)))
        #expect(board.validate(Move(from: .cascade(0), to: .foundation(0))) == nil)
    }

    @Test func freeCellHoldsOneCard() {
        var board = Board()
        board.cascades[0] = cards("9S 8H")
        board.freeCells[0] = card("KD")
        #expect(board.validate(Move(from: .cascade(0), to: .freeCell(0))) == .notAllowed)
        #expect(board.validate(Move(from: .cascade(0), to: .freeCell(1))) == nil)
        #expect(board.validate(Move(from: .cascade(0), to: .freeCell(1), count: 2)) == .onlyOneCard)
    }

    @Test func cardsCannotLeaveFoundation() {
        var board = Board()
        board.foundations[0] = cards("AS")
        #expect(board.validate(Move(from: .foundation(0), to: .freeCell(0))) == .fromFoundation)
    }

    @Test func sequenceMustAlternateAndDescend() {
        var board = Board()
        board.cascades[0] = cards("9S 8H 7C")
        board.cascades[1] = cards("9C 8C")
        #expect(board.isSequence(cascade: 0, from: 0))
        #expect(!board.isSequence(cascade: 1, from: 0))
        board.cascades[2] = cards("TD")
        #expect(board.validate(Move(from: .cascade(0), to: .cascade(2), count: 3)) == nil)
        #expect(board.validate(Move(from: .cascade(1), to: .cascade(2), count: 2)) == .notASequence)
    }

    @Test func supermoveSizeFollowsFreeCellsAndEmptyColumns() {
        var board = Board()
        // Fill every column, then free a known number of cells and columns.
        for i in 0..<8 { board.cascades[i] = [Card(rank: 13, suit: .spades)] }
        board.freeCells = [card("2C"), card("3C"), nil, nil]
        #expect(board.maxMovableCards(toEmptyCascade: false) == 3)
        board.cascades[7] = []
        board.cascades[6] = []
        #expect(board.maxMovableCards(toEmptyCascade: false) == 12)
        #expect(board.maxMovableCards(toEmptyCascade: true) == 6)
    }

    @Test func tooLongSupermoveIsRefused() {
        var board = Board()
        board.cascades[0] = cards("KS QH JC TD 9S")
        board.cascades[1] = cards("KC")
        for i in 2..<8 { board.cascades[i] = cards("2C") }
        board.freeCells = [card("3C"), card("4C"), card("5C"), nil]
        // One free cell and no empty column: two cards at most.
        #expect(board.validate(Move(from: .cascade(0), to: .cascade(1), count: 4)) == .tooManyCards(max: 2))
    }

    @Test func tapPrefersFoundation() {
        var board = Board()
        board.cascades[0] = cards("5D AS")
        board.cascades[1] = cards("2H")
        #expect(board.bestMove(from: .cascade(0), count: 1)?.to == .foundation(0))
    }

    @Test func autoplayMovesOnlySafeCards() {
        var board = Board()
        board.foundations = [cards("AH"), cards("AS"), cards("AD"), []]
        board.cascades[0] = cards("2H")
        board.cascades[1] = cards("3S")
        // A two is always safe.
        #expect(board.safeAutoplayMove() == Move(from: .cascade(0), to: .foundation(0)))
        board.apply(Move(from: .cascade(0), to: .foundation(0)))
        // The red twos are not both up yet, so the 3 of spades may still be needed.
        board.foundations[1] = cards("AS 2S")
        #expect(board.safeAutoplayMove() == nil)
    }

    @Test func boardIsWonWhenFoundationsAreFull() {
        var board = Board()
        board.foundations = Suit.allCases.map { suit in (1...13).map { Card(rank: $0, suit: suit) } }
        #expect(board.isWon)
    }
}
