# Candidate Answer Word Lists (reference only — NOT compiled into the app)

These files live OUTSIDE the `WordGames/WordGames/` source folder on purpose, so Xcode's
file-system-synchronized group does not add them to the build target. They are candidate
replacements for `WordList.possibleAnswers`, kept here for review/version history.

Provenance: vocabulary from Webster's 2nd International (public domain, via the
`english-words` package); commonness ranking from the `wordfreq` project (Apache-2.0).
Selection: 5-letter words, proper nouns excluded, plurals + offensive words removed.

- `LetterLogic_answers_v2.*`   — Balanced mix, zipf >= 2.8, 2,151 words
- `LetterLogic_answers_hard.*` — Hard variant, zipf band [2.8, 4.4), 1,690 words
  (drops trivially-easy words so answers are never giveaways)

`.txt` = human-readable review list (with provenance header).
`.swift` = ready-to-paste `possibleAnswers` array, if/when one is adopted.

To adopt a list: replace the `possibleAnswers` array in
`WordGames/WordList.swift` with the chosen `.swift` file's array. Not yet applied.
