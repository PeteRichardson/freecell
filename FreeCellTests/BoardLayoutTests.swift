import CoreGraphics
import Testing
@testable import FreeCell

struct BoardLayoutTests {
    /// Board sizes (the area below the toolbar) of real screens, in points.
    static let boards: [(name: String, size: CGSize)] = [
        ("iPad 13-inch portrait", CGSize(width: 1032, height: 1250)),
        ("iPad 13-inch landscape", CGSize(width: 1376, height: 920)),
        ("iPad 11-inch landscape", CGSize(width: 1210, height: 760)),
        ("iPad mini landscape", CGSize(width: 1133, height: 670)),
        ("iPhone portrait", CGSize(width: 386, height: 700)),
        ("iPhone landscape", CGSize(width: 780, height: 320)),
    ]

    private func allPiles() -> [Pile] {
        (0..<Board.freeCellCount).map(Pile.freeCell)
            + (0..<Board.foundationCount).map(Pile.foundation)
            + (0..<Board.cascadeCount).map(Pile.cascade)
    }

    @Test func tallScreensPutFreeCellsAboveTheColumns() {
        #expect(BoardLayout(size: CGSize(width: 1032, height: 1250)).arrangement == .topRow)
        #expect(BoardLayout(size: CGSize(width: 1376, height: 920)).arrangement == .topRow)
        #expect(BoardLayout(size: CGSize(width: 386, height: 700)).arrangement == .topRow)
    }

    @Test func shortWideScreensPutFreeCellsAtTheSides() {
        let layout = BoardLayout(size: CGSize(width: 780, height: 320))
        #expect(layout.arrangement == .sides)
        #expect(layout.slotRect(.freeCell(0)).maxX < layout.slotRect(.cascade(0)).minX)
        #expect(layout.slotRect(.foundation(0)).minX > layout.slotRect(.cascade(7)).maxX)
    }

    @Test(arguments: boards)
    func everyPileIsOnTheBoardAndPilesDoNotOverlap(board: (name: String, size: CGSize)) {
        let layout = BoardLayout(size: board.size)
        let bounds = CGRect(origin: .zero, size: board.size)
        let rects = allPiles().map(layout.slotRect)
        for (i, rect) in rects.enumerated() {
            #expect(bounds.contains(rect), "\(board.name): \(allPiles()[i]) is off the board")
            for other in rects[(i + 1)...] {
                #expect(!rect.intersects(other), "\(board.name): piles overlap")
            }
        }
    }

    @Test(arguments: boards)
    func longestColumnFitsOnTheBoard(board: (name: String, size: CGSize)) {
        let layout = BoardLayout(size: board.size)
        let count = BoardLayout.longestColumn
        let last = layout.cardRect(cascade: 0, index: count - 1, count: count)
        #expect(last.maxY <= board.size.height, "\(board.name): the column goes off the board")
    }
}
