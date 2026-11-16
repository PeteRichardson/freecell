import SwiftUI

struct GameView: View {
    @State private var game = GameModel.forLaunch()
    @State private var isConfirmingNewGame = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            BoardView(game: game)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        }
        .background(Felt().ignoresSafeArea())
        .overlay(alignment: .bottom) { messageBanner }
        .overlay {
            if game.isWon {
                VictoryView(dealNumber: game.dealNumber, moveCount: game.moveCount) {
                    game.newGame()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5).delay(game.isWon ? 0.4 : 0), value: game.isWon)
        .sensoryFeedback(.error, trigger: game.refusedMoveCount)
        .sensoryFeedback(.success, trigger: game.isWon) { _, won in won }
        .alert("Abandon this game?", isPresented: $isConfirmingNewGame) {
            Button("New Game", role: .destructive) { game.newGame() }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("This game is not finished. If you start a new game, you lose your progress.")
        }
    }

    @ViewBuilder
    private var toolbar: some View {
        // A narrow screen (iPhone) has room for the button icons only.
        if sizeClass == .compact {
            toolbarContent.labelStyle(.iconOnly)
        } else {
            toolbarContent
        }
    }

    private var toolbarContent: some View {
        HStack {
            Button(action: requestNewGame) {
                Label("New Game", systemImage: "rectangle.stack.badge.plus")
            }
            Spacer()
            Text("Game #\(String(game.dealNumber))")
                .font(.headline)
            Text("Moves: \(game.moveCount)")
                .font(.headline.monospacedDigit())
                .padding(.leading, 16)
            Spacer()
            Button(action: game.undo) {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!game.canUndo)
        }
        .buttonStyle(.bordered)
        .tint(.white)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var messageBanner: some View {
        if let message = game.message {
            Text(message)
                .font(.callout.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }

    private func requestNewGame() {
        if game.isInProgress {
            isConfirmingNewGame = true
        } else {
            game.newGame()
        }
    }
}

/// The green cloth of a card table.
struct Felt: View {
    static let color = Color(red: 0.05, green: 0.40, blue: 0.20)

    var body: some View {
        RadialGradient(
            colors: [Color(red: 0.09, green: 0.52, blue: 0.27), Self.color, Color(red: 0.02, green: 0.25, blue: 0.12)],
            center: .center, startRadius: 50, endRadius: 1100
        )
    }
}

#Preview {
    GameView()
}
