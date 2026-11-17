# Rate the Microsoft deals offline by solver effort

The app offers Easy, Medium and Hard games. We rate the 31,999 solvable Microsoft deals once, on a Mac, by solver effort: `fc-solve`, with one fixed configuration and version and 4 free cells, counts the positions it examines before it solves each deal. The deals are sorted by that count and divided into three equal thirds, and the app contains the resulting ratings file. A new game picks a random deal from the third for the selected difficulty. This keeps the Microsoft deal numbers, so "Game #617" is still the same deal as in other FreeCell programs, starts a game with no wait, and gives fixed ratings that tests can check.

The configuration is Freecell Solver 6.16.0 with its "video-editing" preset. Of the presets we tried, it was the only one that solved every deal and also put the hardest deals that the FreeCell Now Deal Difficulty Index has published (#20024, #5712, #27234, #6674, #3756, #7744, #617) in the hardest 12%. The default preset stopped at 2,000,000 positions on 105 deals, and the fast "looking-glass" preset put #27234 in the easiest 6%. Changing the version or the preset changes the ratings.

`scripts/rate_deals.sh` makes the ratings file again. A deal that the solver does not solve before its limit goes to the hard end. `fc-solve` is needed only to run the script, not to build the app.

## Considered Options

- **The FreeCell Now Deal Difficulty Index**: a published rating of all 32,000 deals in six bands, mostly by solver effort. Rejected because it has no download and the site's terms forbid extracting it. If FreeCell Now gives permission, its ratings can replace ours, and only the ratings file changes.
- **Free-cell need** (the fewest free cells with which a deal can be solved): rejected because it has only five values and most deals share one or two of them, so it cannot make three balanced groups.
- **Make new deals in the app** (for example, by playing back from a solved board): rejected, because the game numbers would no longer be Microsoft numbers.
- **Rate deals in the app when a game starts**: rejected, because a solver can take seconds on a phone and the result could change with the device's time limit.
