import CoreGraphics

/// Where each pile and card goes on a board of a given size.
struct BoardLayout {
    /// Where the free cells and foundations go.
    enum Arrangement {
        /// In one row above the columns. Good for tall screens.
        case topRow
        /// In a 2×2 block on each side of the columns, so that the columns use the full height.
        /// Good for wide, short screens, such as an iPhone in landscape.
        case sides
    }

    static let cardAspect: CGFloat = 1.5
    /// The part of a covered card that shows, as a fraction of card height. It shows the corner index.
    static let preferredOverlap: CGFloat = 0.26
    static let minimumOverlap: CGFloat = 0.1
    /// The longest possible column: seven dealt cards, then a king down to a two.
    static let longestColumn = 19

    let size: CGSize
    let arrangement: Arrangement
    let cardSize: CGSize
    let gap: CGFloat
    private let originX: CGFloat
    private let topY: CGFloat
    private let cascadeY: CGFloat

    init(size: CGSize) {
        self.size = size
        gap = max(4, min(16, size.width * 0.012))
        let columns = CGFloat(Board.cascadeCount)
        // A column needs room for the first seven cards at the preferred overlap,
        // and for the longest column at the minimum overlap. The value is in card heights.
        let columnHeight = max(1 + 6 * Self.preferredOverlap, 1 + CGFloat(Self.longestColumn - 1) * Self.minimumOverlap)

        let topRowWidth = min(
            (size.width - gap * (columns + 1)) / columns,
            (size.height - gap * 3.5) / (Self.cardAspect * (1 + columnHeight))
        )
        // Two columns on each side, with one more gap between the blocks and the columns.
        let sidesWidth = min(
            (size.width - gap * (columns + 7)) / (columns + 4),
            (size.height - gap * 2) / (Self.cardAspect * columnHeight),
            (size.height - gap * 3) / (Self.cardAspect * 2)
        )
        // The side blocks give the columns much more height, so they win when the cards are almost as large.
        arrangement = sidesWidth > topRowWidth * 0.9 ? .sides : .topRow

        let width = max(10, arrangement == .sides ? sidesWidth : topRowWidth)
        cardSize = CGSize(width: width, height: width * Self.cardAspect)
        topY = gap
        switch arrangement {
        case .topRow:
            originX = (size.width - (width * columns + gap * (columns - 1))) / 2
            cascadeY = topY + cardSize.height + gap * 1.5
        case .sides:
            originX = (size.width - (width * (columns + 4) + gap * (columns + 5))) / 2
            cascadeY = topY
        }
    }

    var cornerRadius: CGFloat { cardSize.width * 0.06 }

    private func columnX(_ column: Int) -> CGFloat {
        originX + CGFloat(column) * (cardSize.width + gap)
    }

    /// The rectangle of the empty pile, or of its first card.
    func slotRect(_ pile: Pile) -> CGRect {
        switch (arrangement, pile) {
        case (.topRow, .freeCell(let i)):
            rect(x: columnX(i), y: topY)
        case (.topRow, .foundation(let i)):
            rect(x: columnX(Board.freeCellCount + i), y: topY)
        case (.topRow, .cascade(let i)):
            rect(x: columnX(i), y: cascadeY)
        case (.sides, .freeCell(let i)):
            blockRect(firstColumn: 0, index: i)
        case (.sides, .foundation(let i)):
            blockRect(firstColumn: 2 + Board.cascadeCount, index: i, extraGaps: 2)
        case (.sides, .cascade(let i)):
            rect(x: columnX(2 + i) + gap, y: cascadeY)
        }
    }

    private func rect(x: CGFloat, y: CGFloat) -> CGRect {
        CGRect(origin: CGPoint(x: x, y: y), size: cardSize)
    }

    /// A pile in a 2×2 block at the side of the board.
    private func blockRect(firstColumn: Int, index: Int, extraGaps: CGFloat = 0) -> CGRect {
        rect(x: columnX(firstColumn + index % 2) + gap * extraGaps,
             y: topY + CGFloat(index / 2) * (cardSize.height + gap))
    }

    /// The distance between cards in a column. Long columns get closer together so that they fit.
    func overlap(cardCount: Int) -> CGFloat {
        guard cardCount > 1 else { return 0 }
        let room = (size.height - gap - cascadeY - cardSize.height) / CGFloat(cardCount - 1)
        return max(cardSize.height * Self.minimumOverlap, min(cardSize.height * Self.preferredOverlap, room))
    }

    func cardRect(cascade column: Int, index: Int, count: Int) -> CGRect {
        slotRect(.cascade(column)).offsetBy(dx: 0, dy: CGFloat(index) * overlap(cardCount: count))
    }

    /// The pile under a dragged card: the one whose area overlaps the card most.
    func dropTarget(for frame: CGRect) -> Pile? {
        var zones: [(Pile, CGRect)] = []
        for i in 0..<Board.freeCellCount { zones.append((.freeCell(i), slotRect(.freeCell(i)))) }
        for i in 0..<Board.foundationCount { zones.append((.foundation(i), slotRect(.foundation(i)))) }
        for i in 0..<Board.cascadeCount {
            let top = slotRect(.cascade(i))
            zones.append((.cascade(i), CGRect(x: top.minX, y: top.minY, width: top.width, height: size.height - top.minY)))
        }

        var best: (pile: Pile, area: CGFloat)?
        for (pile, zone) in zones {
            let overlap = frame.intersection(zone.insetBy(dx: -gap / 2, dy: -gap / 2))
            guard !overlap.isNull else { continue }
            let area = overlap.width * overlap.height
            if area > (best?.area ?? 0) { best = (pile, area) }
        }
        return best?.pile
    }
}
