import SwiftUI

/// What the menu bar can do to the game in the front window.
struct GameActions {
    let canUndo: Bool
    let difficulty: Binding<Difficulty>
    let newGame: () -> Void
    let undo: () -> Void
}

struct GameActionsKey: FocusedValueKey {
    typealias Value = GameActions
}

extension FocusedValues {
    var gameActions: GameActions? {
        get { self[GameActionsKey.self] }
        set { self[GameActionsKey.self] = newValue }
    }
}

/// The menu bar commands: New Game (⌘N), Undo (⌘Z) and the Difficulty menu. On a Mac they are in
/// the menu bar. On an iPad with a keyboard, they are in the menu bar and in the keyboard shortcuts.
struct GameCommands: Commands {
    @FocusedValue(\.gameActions) private var actions

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Game") { actions?.newGame() }
                .keyboardShortcut("n")
                .disabled(actions == nil)
        }
        CommandGroup(replacing: .undoRedo) {
            Button("Undo") { actions?.undo() }
                .keyboardShortcut("z")
                .disabled(actions?.canUndo != true)
        }
        CommandMenu("Difficulty") {
            Picker("Difficulty", selection: actions?.difficulty ?? .constant(.easy)) {
                ForEach(Difficulty.allCases) { difficulty in
                    Text(difficulty.name).tag(difficulty)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            .disabled(actions == nil)
        }
    }
}
