import SwiftUI

/// The free cells, foundations and cascades. All 52 cards are in one ZStack, so a card that
/// changes pile moves smoothly to its new place.
struct BoardView: View {
    let game: GameModel
    @State private var drag: DragState?

    private struct DragState {
        var source: Pile
        var count: Int
        var cardIDs: Set<Int>
        /// False when the touched cards cannot move together. Then they stay in place.
        var isValid: Bool
        var translation: CGSize = .zero
        var target: Pile?
        var targetIsLegal = false
    }

    private struct PlacedCard: Identifiable {
        let card: Card
        let pile: Pile
        let index: Int
        let frame: CGRect
        var id: Int { card.id }
    }

    private static let space = "board"

    var body: some View {
        GeometryReader { geometry in
            let layout = BoardLayout(size: geometry.size)
            ZStack(alignment: .topLeading) {
                slots(layout)
                ForEach(placedCards(layout)) { placed in
                    card(placed, layout: layout)
                }
                targetHighlight(layout)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .coordinateSpace(.named(Self.space))
            .allowsHitTesting(!game.isAutoplaying && !game.isWon)
        }
    }

    // MARK: - Drawing

    private func slots(_ layout: BoardLayout) -> some View {
        let piles = (0..<Board.freeCellCount).map(Pile.freeCell)
            + (0..<Board.foundationCount).map(Pile.foundation)
            + (0..<Board.cascadeCount).map(Pile.cascade)
        return ForEach(piles, id: \.self) { pile in
            let rect = layout.slotRect(pile)
            RoundedRectangle(cornerRadius: layout.cornerRadius)
                .fill(.black.opacity(0.15))
                .strokeBorder(.white.opacity(0.3), lineWidth: 1.5)
                .overlay {
                    if case .foundation = pile {
                        Text("A")
                            .font(.system(size: layout.cardSize.width * 0.4, weight: .semibold, design: .serif))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
        }
    }

    private func card(_ placed: PlacedCard, layout: BoardLayout) -> some View {
        let isDragged = drag?.isValid == true && drag?.cardIDs.contains(placed.card.id) == true
        let offset = isDragged ? drag!.translation : .zero
        var z = Double(placed.index)
        if game.lastMovedCardIDs.contains(placed.card.id) { z += 100 }
        if isDragged { z += 200 }

        return CardView(card: placed.card, cornerRadius: layout.cornerRadius)
            .frame(width: layout.cardSize.width, height: layout.cardSize.height)
            .shadow(color: .black.opacity(isDragged ? 0.45 : 0.25), radius: isDragged ? 8 : 1.5, y: isDragged ? 4 : 1)
            .contentShape(RoundedRectangle(cornerRadius: layout.cornerRadius))
            .onTapGesture { game.autoMove(from: placed.pile, index: placed.index) }
            .gesture(dragGesture(for: placed, layout: layout))
            .position(x: placed.frame.midX + offset.width, y: placed.frame.midY + offset.height)
            .zIndex(z)
    }

    @ViewBuilder
    private func targetHighlight(_ layout: BoardLayout) -> some View {
        if let drag, drag.targetIsLegal, let target = drag.target {
            let rect = targetRect(target, layout: layout)
            RoundedRectangle(cornerRadius: layout.cornerRadius)
                .strokeBorder(.yellow, lineWidth: 3)
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .zIndex(150)
                .allowsHitTesting(false)
        }
    }

    /// The rectangle of the card that the dragged cards will go on, or of the empty pile.
    private func targetRect(_ pile: Pile, layout: BoardLayout) -> CGRect {
        guard case .cascade(let column) = pile else { return layout.slotRect(pile) }
        let count = game.board.cascades[column].count
        return layout.cardRect(cascade: column, index: max(0, count - 1), count: count)
    }

    private func placedCards(_ layout: BoardLayout) -> [PlacedCard] {
        let board = game.board
        var result: [PlacedCard] = []
        for (i, card) in board.freeCells.enumerated() {
            if let card {
                result.append(PlacedCard(card: card, pile: .freeCell(i), index: 0, frame: layout.slotRect(.freeCell(i))))
            }
        }
        for (i, pile) in board.foundations.enumerated() {
            for (j, card) in pile.enumerated() {
                result.append(PlacedCard(card: card, pile: .foundation(i), index: j, frame: layout.slotRect(.foundation(i))))
            }
        }
        for (i, column) in board.cascades.enumerated() {
            for (j, card) in column.enumerated() {
                let frame = layout.cardRect(cascade: i, index: j, count: column.count)
                result.append(PlacedCard(card: card, pile: .cascade(i), index: j, frame: frame))
            }
        }
        return result
    }

    // MARK: - Dragging

    private func dragGesture(for placed: PlacedCard, layout: BoardLayout) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(Self.space))
            .onChanged { value in
                if drag == nil { drag = startDrag(placed) }
                guard var state = drag, state.isValid else { return }
                state.translation = value.translation
                let frame = placed.frame.offsetBy(dx: value.translation.width, dy: value.translation.height)
                let target = layout.dropTarget(for: frame).flatMap { $0 == state.source ? nil : $0 }
                state.target = target
                state.targetIsLegal = target.map {
                    game.board.validate(Move(from: state.source, to: $0, count: state.count)) == nil
                } ?? false
                drag = state
            }
            .onEnded { _ in
                guard let state = drag else { return }
                if state.isValid, let target = state.target,
                   game.perform(Move(from: state.source, to: target, count: state.count)) {
                    withAnimation(GameModel.moveAnimation) { drag = nil }
                } else {
                    withAnimation(.spring(duration: 0.3)) { drag = nil }
                }
            }
    }

    private func startDrag(_ placed: PlacedCard) -> DragState {
        let cards = game.board.cards(in: placed.pile)
        let count = cards.count - placed.index
        let ids = Set(cards.suffix(count).map(\.id))
        var isValid = true
        switch placed.pile {
        case .foundation:
            isValid = false
        case .cascade(let column):
            if !game.board.isSequence(cascade: column, from: placed.index) {
                isValid = false
                game.refuse(.notASequence)
            }
        case .freeCell:
            break
        }
        return DragState(source: placed.pile, count: count, cardIDs: ids, isValid: isValid)
    }
}
