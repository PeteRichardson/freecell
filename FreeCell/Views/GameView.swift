import SwiftUI

struct GameView: View {
    @State private var setting: DifficultySetting
    @State private var game: GameModel
    @State private var isConfirmingNewGame = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    init() {
        let setting = DifficultySetting()
        _setting = State(initialValue: setting)
        _game = State(initialValue: GameModel.forLaunch(difficulty: setting.difficulty))
    }

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
                VictoryView(dealNumber: game.dealNumber, difficulty: game.difficulty, moveCount: game.moveCount) {
                    startNewGame()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5).delay(game.isWon ? 0.4 : 0), value: game.isWon)
        .sensoryFeedback(.error, trigger: game.refusedMoveCount)
        .sensoryFeedback(.success, trigger: game.isWon) { _, won in won }
        .alert("Abandon this game?", isPresented: $isConfirmingNewGame) {
            Button("New Game", role: .destructive, action: startNewGame)
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
            newGameMenu
            Spacer()
            // On a narrow screen, the title becomes smaller before it goes onto two lines.
            Text(title)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Moves: \(game.moveCount)")
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .padding(.leading, sizeClass == .compact ? 8 : 16)
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

    /// A tap starts a new game. A long press opens the menu, where the player selects the
    /// difficulty of the next new game. A change of difficulty does not change the current game.
    private var newGameMenu: some View {
        Menu {
            Picker("Difficulty", selection: $setting.difficulty) {
                ForEach(Difficulty.allCases) { difficulty in
                    Text(difficulty.name).tag(difficulty)
                }
            }
            Button(action: requestNewGame) {
                Label("New \(setting.difficulty.name) Game", systemImage: "rectangle.stack.badge.plus")
            }
        } label: {
            Label("New Game", systemImage: "rectangle.stack.badge.plus")
        } primaryAction: {
            requestNewGame()
        }
    }

    /// The deal number and its difficulty, for example "Game #617 · Hard".
    private var title: String {
        let number = "Game #\(String(game.dealNumber))"
        guard let difficulty = game.difficulty else { return number }
        return "\(number) · \(difficulty.name)"
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
            startNewGame()
        }
    }

    private func startNewGame() {
        game.newGame(difficulty: setting.difficulty)
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
