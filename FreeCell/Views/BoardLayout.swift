import CoreGraphics

/// Where each pile and card goes on a board of a given size.
struct BoardLayout {
    static let cardAspect: CGFloat = 1.5
    /// The part of a covered card that shows, as a fraction of card height. It shows the corner index.
    static let preferredOverlap: CGFloat = 0.26
    static let minimumOverlap: CGFloat = 0.1

    let size: CGSize
    let cardSize: CGSize
    let gap: CGFloat
    private let originX: CGFloat
    private let topY: CGFloat
    private let cascadeY: CGFloat

    init(size: CGSize) {
        self.size = size
        gap = max(4, min(16, size.width * 0.012))
        let columns = CGFloat(Board.cascadeCount)
        let widthLimit = (size.width - gap * (columns + 1)) / columns
        // Leave room for the top row and a full starting column of seven cards.
        let heightLimit = (size.height - gap * 3) / (Self.cardAspect * (2 + 6 * Self.preferredOverlap))
        let width = max(10, min(widthLimit, heightLimit))
        cardSize = CGSize(width: width, height: width * Self.cardAspect)
        originX = (size.width - (width * columns + gap * (columns - 1))) / 2
        topY = gap
        cascadeY = topY + cardSize.height + gap * 1.5
    }

    var cornerRadius: CGFloat { cardSize.width * 0.06 }

    private func columnX(_ column: Int) -> CGFloat {
        originX + CGFloat(column) * (cardSize.width + gap)
    }

    /// The rectangle of the empty pile, or of its first card.
    func slotRect(_ pile: Pile) -> CGRect {
        switch pile {
        case .freeCell(let i):
            CGRect(origin: CGPoint(x: columnX(i), y: topY), size: cardSize)
        case .foundation(let i):
            CGRect(origin: CGPoint(x: columnX(Board.freeCellCount + i), y: topY), size: cardSize)
        case .cascade(let i):
            CGRect(origin: CGPoint(x: columnX(i), y: cascadeY), size: cardSize)
        }
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
