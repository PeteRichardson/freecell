import Testing
@testable import FreeCell

@MainActor
struct GameModelTests {
    /// Every card is on a foundation except the four kings, which are in the free cells.
    private func boardWithKingsInFreeCells() -> Board {
        var board = Board()
        board.foundations = Suit.allCases.map { suit in (1...12).map { Card(rank: $0, suit: suit) } }
        board.freeCells = Suit.allCases.map { Card(rank: 13, suit: $0) }
        return board
    }

    @Test func playerMoveThenAutoplayWinsTheGame() async {
        var board = boardWithKingsInFreeCells()
        // Put the king of spades in a column, so the player has one move to make.
        board.freeCells[3] = nil
        board.cascades[0] = [Card(rank: 13, suit: .spades)]
        board.foundations[3].removeLast()
        board.cascades[1] = [Card(rank: 12, suit: .spades)]
        let game = GameModel(board: board)
        #expect(!game.isWon)

        #expect(game.perform(Move(from: .cascade(1), to: .foundation(3))))
        await game.waitForAutoplay()
        #expect(game.isWon)
        #expect(game.moveCount == 1)
        #expect(!game.isInProgress)
    }

    @Test func illegalMoveIsRefusedAndBoardStaysTheSame() {
        var board = Board()
        board.cascades[0] = [Card(rank: 9, suit: .hearts)]
        board.cascades[1] = [Card(rank: 5, suit: .clubs)]
        let game = GameModel(board: board)
        #expect(!game.perform(Move(from: .cascade(1), to: .cascade(0))))
        #expect(game.board == board)
        #expect(game.refusedMoveCount == 1)
        #expect(game.message != nil)
        #expect(game.moveCount == 0)
    }

    @Test func undoRestoresTheBoard() async {
        var board = Board()
        board.cascades[0] = [Card(rank: 9, suit: .hearts)]
        board.cascades[1] = [Card(rank: 8, suit: .clubs)]
        let game = GameModel(board: board)
        #expect(game.perform(Move(from: .cascade(1), to: .cascade(0))))
        await game.waitForAutoplay()
        #expect(game.isInProgress)
        game.undo()
        #expect(game.board == board)
        #expect(game.moveCount == 0)
    }

    @Test func newGameDealsFreshBoard() async {
        let game = GameModel(dealNumber: 1)
        game.newGame(number: 2)
        #expect(game.dealNumber == 2)
        #expect(game.moveCount == 0)
        #expect(!game.canUndo)
    }
}
