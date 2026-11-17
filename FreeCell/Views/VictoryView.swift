import SwiftUI

struct VictoryView: View {
    let dealNumber: Int
    let difficulty: Difficulty?
    let moveCount: Int
    let onNewGame: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            ConfettiView().ignoresSafeArea().allowsHitTesting(false)
            VStack(spacing: 16) {
                Text("You Won!")
                    .font(.system(size: 56, weight: .bold, design: .serif))
                Text("You solved \(difficulty.map { $0.name.lowercased() + " " } ?? "")game #\(String(dealNumber)) in \(moveCount) moves.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                Button("New Game", action: onNewGame)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Felt.color)
                    .padding(.top, 8)
            }
            .padding(40)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
            .shadow(radius: 20)
            .padding()
        }
    }
}

/// Suit symbols that fall down the screen.
private struct ConfettiView: View {
    private struct Piece {
        let x: Double
        let start: Double
        let speed: Double
        let sway: Double
        let phase: Double
        let spin: Double
        let size: Double
        let symbol: String
        let color: Color
    }

    @State private var startDate = Date()
    @State private var pieces: [Piece] = (0..<90).map { _ in
        let symbol = ["♠", "♥", "♦", "♣"].randomElement()!
        let colors: [Color] = symbol == "♥" || symbol == "♦" ? [.red, .pink, .orange] : [.black, .indigo, .yellow]
        return Piece(
            x: .random(in: 0...1),
            start: .random(in: -1...0),
            speed: .random(in: 0.12...0.3),
            sway: .random(in: 10...40),
            phase: .random(in: 0...(2 * .pi)),
            spin: .random(in: -3...3),
            size: .random(in: 18...42),
            symbol: symbol,
            color: colors.randomElement()!
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince(startDate)
            Canvas { context, size in
                for piece in pieces {
                    let progress = (piece.start + time * piece.speed).truncatingRemainder(dividingBy: 1.2)
                    guard progress >= 0 else { continue }
                    let x = piece.x * size.width + sin(time * 2 + piece.phase) * piece.sway
                    let y = (progress - 0.1) * size.height
                    var copy = context
                    copy.translateBy(x: x, y: y)
                    copy.rotate(by: .radians(time * piece.spin + piece.phase))
                    let text = Text(piece.symbol).font(.system(size: piece.size)).foregroundStyle(piece.color)
                    copy.draw(copy.resolve(text), at: .zero)
                }
            }
        }
    }
}

#Preview {
    VictoryView(dealNumber: 617, difficulty: .hard, moveCount: 92) {}
        .background(Felt())
}
