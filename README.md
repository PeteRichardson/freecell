# FreeCell

A FreeCell solitaire game for iPad (and iPhone), written in SwiftUI. No ads, no purchases.

The rules are the standard rules from [Wikipedia](https://en.wikipedia.org/wiki/FreeCell):
four free cells, four foundations, eight columns, build down in alternate colours.
The game numbers use the Microsoft deal algorithm, so "Game #617" is the same deal as in
other FreeCell programs.

## How to play

- **Tap** a card to send it to the best legal place (foundation first, then a column, then a free cell).
- **Drag** a card, or a sequence of cards, to a pile. A yellow frame shows a legal drop place.
- Sequences move as one "supermove". The largest size is (empty free cells + 1) × 2^(empty columns).
- Cards that no other card can need go to the foundations automatically.
- **Undo** reverses the last move. **New Game** asks before it abandons a game in progress.
- The board works in portrait and landscape. On a wide, short screen (an iPhone in landscape), the free cells and foundations move to the sides, so that the columns have more height.

## Build

Open `FreeCell.xcodeproj` in Xcode 26 or later and run the `FreeCell` scheme.
The app needs iOS 17 or later. To install on your own iPad, select your team under
*Signing & Capabilities*.

Run the tests with:

```sh
xcodebuild -scheme FreeCell -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test
```

Debug builds accept two launch arguments (set them in the scheme, under *Run > Arguments*):
`-deal 617` starts a known deal, and `-nearlyWon` starts a game that wins at once, to show the victory screen.

## Project layout

| Path | Contents |
| --- | --- |
| `FreeCell/Model/Board.swift` | The rules: legal moves, supermoves, safe automatic moves |
| `FreeCell/Model/Deal.swift` | Microsoft-numbered deals |
| `FreeCell/Model/GameModel.swift` | Game state, undo, automatic moves |
| `FreeCell/Views/` | SwiftUI views: board layout, drag and drop, victory screen |
| `FreeCellTests/` | Unit tests of the rules and the game model |
| `FreeCellUITests/` | UI tests: tap, drag, illegal drag, New Game confirmation, landscape |
| `scripts/make_assets.sh` | Makes the card images from the SVG files |

## Card art

The card images are the "English pattern" playing cards by Dmitry Fomin, from
[Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:SVG_English_pattern_playing_cards).
They are released under CC0 (public domain).
