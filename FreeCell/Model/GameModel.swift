import SwiftUI

/// One game of FreeCell: the board, the undo history, and the automatic moves to the foundations.
@MainActor @Observable
final class GameModel {
    private(set) var board: Board
    private(set) var dealNumber: Int
    private(set) var moveCount = 0
    /// True while cards go to the foundations by themselves. The board does not accept input then.
    private(set) var isAutoplaying = false
    /// The cards that moved last. The view draws them above other cards while they fly.
    private(set) var lastMovedCardIDs: Set<Int> = []
    /// A short text that tells why a move is not allowed.
    private(set) var message: String?
    /// Goes up by one for each refused move, to start haptic feedback.
    private(set) var refusedMoveCount = 0

    private var history: [(board: Board, moveCount: Int)] = []
    private var autoplayTask: Task<Void, Never>?
    private var messageTask: Task<Void, Never>?

    /// The difficulty of the deal on the board, or nil if the deal has no rating.
    var difficulty: Difficulty? { Deal.difficulty(of: dealNumber) }
    var isWon: Bool { board.isWon }
    var canUndo: Bool { !history.isEmpty && !isAutoplaying && !isWon }
    /// True when a new game would throw away the player's work.
    var isInProgress: Bool { moveCount > 0 && !isWon }

    static let moveAnimation = Animation.easeInOut(duration: 0.22)

    init(dealNumber: Int) {
        self.dealNumber = dealNumber
        self.board = Deal.board(number: dealNumber)
        startAutoplay()
    }

    /// Starts from a given board. For tests.
    init(board: Board) {
        self.dealNumber = 0
        self.board = board
    }

    /// The game at app launch: a random deal of the given difficulty. In a debug build, the launch
    /// argument `-nearlyWon` gives a game that wins by itself, to show the victory screen, and
    /// `-deal <number>` gives a known deal.
    static func forLaunch(difficulty: Difficulty) -> GameModel {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let i = arguments.firstIndex(of: "-deal"), i + 1 < arguments.count, let number = Int(arguments[i + 1]) {
            return GameModel(dealNumber: number)
        }
        if arguments.contains("-nearlyWon") {
            var board = Board()
            board.foundations = Suit.allCases.map { suit in (1...12).map { Card(rank: $0, suit: suit) } }
            board.freeCells = Suit.allCases.map { Card(rank: 13, suit: $0) }
            let game = GameModel(board: board)
            game.startAutoplay()
            return game
        }
        #endif
        return GameModel(dealNumber: Deal.randomNumber(difficulty: difficulty))
    }

    /// Waits until the automatic moves to the foundations are done. For tests.
    func waitForAutoplay() async {
        await autoplayTask?.value
    }

    /// Starts a random deal of the given difficulty.
    func newGame(difficulty: Difficulty) {
        newGame(number: Deal.randomNumber(difficulty: difficulty))
    }

    func newGame(number: Int) {
        autoplayTask?.cancel()
        isAutoplaying = false
        history.removeAll()
        lastMovedCardIDs = []
        clearMessage()
        withAnimation(.easeInOut(duration: 0.4)) {
            dealNumber = number
            moveCount = 0
            board = Deal.board(number: number)
        }
        startAutoplay()
    }

    func undo() {
        guard canUndo, let last = history.popLast() else { return }
        clearMessage()
        withAnimation(Self.moveAnimation) {
            lastMovedCardIDs = []
            board = last.board
            moveCount = last.moveCount
        }
    }

    /// Does a move for the player. Returns false, and tells the player why, if the rules do not allow it.
    @discardableResult
    func perform(_ move: Move) -> Bool {
        guard !isAutoplaying, !isWon else { return false }
        if let error = board.validate(move) {
            refuse(error)
            return false
        }
        clearMessage()
        history.append((board, moveCount))
        withAnimation(Self.moveAnimation) {
            lastMovedCardIDs = Set(board.cards(in: move.from).suffix(move.count).map(\.id))
            board.apply(move)
            moveCount += 1
        }
        startAutoplay()
        return true
    }

    /// Moves the cards from `index` to the end of `pile` to the best place for them, after a tap.
    func autoMove(from pile: Pile, index: Int) {
        guard !isAutoplaying, !isWon else { return }
        let cards = board.cards(in: pile)
        let count = cards.count - index
        if case .foundation = pile { return }
        if case .cascade(let column) = pile, !board.isSequence(cascade: column, from: index) {
            refuse(.notASequence)
            return
        }
        guard let move = board.bestMove(from: pile, count: count) else {
            let limit = board.maxMovableCards(toEmptyCascade: false)
            refuse(count > limit ? .tooManyCards(max: limit) : .notAllowed)
            return
        }
        perform(move)
    }

    func refuse(_ error: MoveError) {
        guard !error.message.isEmpty else { return }
        refusedMoveCount += 1
        show(error.message)
    }

    private func startAutoplay() {
        autoplayTask?.cancel()
        autoplayTask = Task { [weak self] in
            await self?.autoplay()
        }
    }

    private func autoplay() async {
        while let move = board.safeAutoplayMove() {
            isAutoplaying = true
            try? await Task.sleep(for: .milliseconds(120))
            if Task.isCancelled { return }
            withAnimation(Self.moveAnimation) {
                lastMovedCardIDs = Set(board.cards(in: move.from).suffix(1).map(\.id))
                board.apply(move)
            }
        }
        isAutoplaying = false
    }

    private func show(_ text: String) {
        messageTask?.cancel()
        withAnimation { message = text }
        messageTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation { self?.message = nil }
        }
    }

    private func clearMessage() {
        messageTask?.cancel()
        if message != nil { withAnimation { message = nil } }
    }
}
