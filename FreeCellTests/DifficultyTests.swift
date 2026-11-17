import Foundation
import Testing
@testable import FreeCell

struct DealDifficultyTests {
    @Test func everySolvableDealHasADifficulty() {
        for number in Deal.range where number != Deal.unsolvable {
            #expect(Deal.difficulty(of: number) != nil, "deal \(number)")
        }
        #expect(Deal.difficulty(of: Deal.unsolvable) == nil)
        #expect(Deal.difficulty(of: 0) == nil)
        #expect(Deal.difficulty(of: 32001) == nil)
    }

    @Test func difficultiesAreEqualThirds() {
        #expect(Deal.numbers(of: .easy).count == 10666)
        #expect(Deal.numbers(of: .medium).count == 10666)
        #expect(Deal.numbers(of: .hard).count == 10667)
    }

    /// #2217 needs the least solver effort of all deals. #617 and #1941 are well-known hard deals.
    @Test func knownDealsHaveTheirDifficulty() {
        #expect(Deal.difficulty(of: 2217) == .easy)
        #expect(Deal.difficulty(of: 1) == .medium)
        #expect(Deal.difficulty(of: 617) == .hard)
        #expect(Deal.difficulty(of: 1941) == .hard)
    }

    @Test(arguments: Difficulty.allCases)
    func randomDealHasTheRequestedDifficulty(difficulty: Difficulty) {
        for _ in 0..<50 {
            #expect(Deal.difficulty(of: Deal.randomNumber(difficulty: difficulty)) == difficulty)
        }
    }
}

@MainActor
struct GameDifficultyTests {
    @Test func gameShowsTheDifficultyOfItsDeal() {
        #expect(GameModel(dealNumber: 617).difficulty == .hard)
        #expect(GameModel(dealNumber: Deal.unsolvable).difficulty == nil)
    }

    @Test func newGameUsesTheRequestedDifficulty() {
        let game = GameModel(dealNumber: 617)
        game.newGame(difficulty: .easy)
        #expect(game.difficulty == .easy)
        #expect(game.moveCount == 0)
    }
}

@MainActor
struct DifficultySettingTests {
    /// A store on this device that no other test uses.
    private func emptyStore() -> UserDefaults {
        let name = "DifficultySettingTests.\(UUID())"
        let store = UserDefaults(suiteName: name)!
        store.removePersistentDomain(forName: name)
        return store
    }

    @Test func defaultIsEasy() {
        #expect(DifficultySetting(local: emptyStore(), cloud: nil).difficulty == .easy)
    }

    @Test func changeIsKeptOnTheDevice() {
        let store = emptyStore()
        DifficultySetting(local: store, cloud: nil).difficulty = .hard
        #expect(DifficultySetting(local: store, cloud: nil).difficulty == .hard)
    }

    @Test func unknownStoredValueGivesEasy() {
        let store = emptyStore()
        store.set("impossible", forKey: DifficultySetting.key)
        #expect(DifficultySetting(local: store, cloud: nil).difficulty == .easy)
    }
}
