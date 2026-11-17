# FreeCell

A solitaire game played on Microsoft-numbered deals with the standard Wikipedia rules.

## Language

**Deal**:
A numbered start layout of the 52 cards, from 1 to 32000, as in the Microsoft FreeCell numbering.
_Avoid_: Board (for the start layout), seed, puzzle

**Game**:
One play of a deal, from the start layout to a win or until the player abandons it.
_Avoid_: Round, session, hand

**Solver effort**:
The number of positions a fixed FreeCell solver examines before it finds a solution to a deal.
_Avoid_: Iterations, difficulty score

**Difficulty**:
How hard a deal is, as one of Easy, Medium or Hard: the third of the deals, sorted by solver effort, that contains the deal. Every deal has one fixed difficulty, and the player's setting selects the difficulty of the next deal.
_Avoid_: Level, mode, band
