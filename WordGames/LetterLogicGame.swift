import SwiftUI
import Combine

// MARK: - LetterLogicGame

@MainActor
final class LetterLogicGame: ObservableObject {

    // MARK: Board
    @Published var tiles: [[String]]      = blankBoardStrings()
    @Published var tileStates: [[TileState]] = blankBoardStates()
    @Published var letterStates: [Character: LetterState] = [:]

    // MARK: Progress
    @Published var currentRow: Int = 0
    @Published var currentCol: Int = 0
    @Published var gameState: GameState = .playing

    // MARK: Animations
    @Published var shakingRow: Int?      = nil
    @Published var revealingRow: Int?    = nil   // row currently mid-flip
    @Published var revealDelays: [Double] = Array(repeating: 0, count: 5)
    @Published var showConfetti: Bool    = false

    // MARK: Toast
    @Published var toastMessage: String? = nil

    // MARK: Stats
    @Published var statistics: Statistics = Statistics()

    // MARK: Word selection
    @Published private(set) var puzzleNumber: Int = 0
    private(set) var secretWord: String = ""
    private var usedAnswers: Set<String> = []   // answers already played; no repeats until exhausted

    // MARK: Settings (persisted)
    @AppStorage("soundEnabled")    var soundEnabled: Bool = true
    @AppStorage("hardMode")        var hardMode: Bool    = false

    /// Selected tile color scheme. Stored as the palette's raw string.
    @AppStorage("tilePalette")     var paletteRaw: String = TilePalette.cool.rawValue

    /// Convenience accessor for the current palette.
    var palette: TilePalette {
        get { TilePalette(rawValue: paletteRaw) ?? .cool }
        set { paletteRaw = newValue.rawValue }
    }

    // Theme is @Published (not @AppStorage) so views re-render live when it
    // flips; persistence is handled manually in didSet / init.
    @Published var darkTheme: Bool = true {
        didSet { UserDefaults.standard.set(darkTheme, forKey: "darkTheme") }
    }

    // MARK: Private
    private let validWords: Set<String>
    private var toastTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        validWords = Set(WordList.allWords.map { $0.uppercased() })
        if let saved = UserDefaults.standard.object(forKey: "darkTheme") as? Bool {
            darkTheme = saved
        }
        // One-time migration: users who had the old high-contrast (color-blind)
        // toggle on are moved to the new accessible palette.
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "tilePalette") == nil,
           defaults.bool(forKey: "highContrast") {
            defaults.set(TilePalette.accessible.rawValue, forKey: "tilePalette")
        }
        loadStatistics()
        loadUsedAnswers()
        puzzleNumber = UserDefaults.standard.integer(forKey: puzzleNumberKey)
        if !attemptRestoreGame() { newGame() }
    }

    // MARK: - Game Setup

    /// Starts a fresh puzzle with a random answer that hasn't been used yet.
    func newGame() {
        secretWord = pickNextAnswer()
        puzzleNumber += 1
        UserDefaults.standard.set(puzzleNumber, forKey: puzzleNumberKey)
        resetBoard()
        saveGame()
    }

    /// Picks a random answer not yet played. Once every answer has been used,
    /// the pool reshuffles (used set clears) so play can continue indefinitely.
    private func pickNextAnswer() -> String {
        let all = WordList.answers.map { $0.uppercased() }
        var remaining = all.filter { !usedAnswers.contains($0) }
        if remaining.isEmpty {
            usedAnswers.removeAll()
            remaining = all
        }
        let word = remaining.randomElement() ?? "CRANE"
        usedAnswers.insert(word)
        saveUsedAnswers()
        return word
    }

    private func resetBoard() {
        tiles       = Self.blankBoardStrings()
        tileStates  = Self.blankBoardStates()
        letterStates = [:]
        currentRow  = 0
        currentCol  = 0
        gameState   = .playing
        revealingRow = nil
        showConfetti = false
        toastMessage = nil
    }

    // MARK: - Input

    func addLetter(_ letter: String) {
        guard gameState == .playing,
              currentCol < 5,
              revealingRow == nil else { return }

        tiles[currentRow][currentCol]      = letter.uppercased()
        tileStates[currentRow][currentCol] = .filled
        currentCol += 1

        if soundEnabled { SoundManager.shared.keyTap() }
        // The per-tile "pop" animation is driven by TileView's
        // onChange(of: letter), so no extra published state or timer is
        // needed here — this keeps each keystroke to a single view update.
    }

    func deleteLetter() {
        guard gameState == .playing,
              currentCol > 0,
              revealingRow == nil else { return }
        currentCol -= 1
        tiles[currentRow][currentCol]      = ""
        tileStates[currentRow][currentCol] = .empty

        if soundEnabled { SoundManager.shared.keyDelete() }
    }

    func submitGuess() {
        guard gameState == .playing,
              currentCol == 5,
              revealingRow == nil else { return }

        let guess = tiles[currentRow].joined()

        guard validWords.contains(guess) else {
            toast("Not in word list")
            triggerShake(row: currentRow)
            if soundEnabled { SoundManager.shared.invalid() }
            return
        }

        if let violation = hardModeViolation(for: guess) {
            toast(violation)
            triggerShake(row: currentRow)
            if soundEnabled { SoundManager.shared.invalid() }
            return
        }

        let result = evaluate(guess: guess, against: secretWord)
        let row    = currentRow

        // Write final colors synchronously BEFORE starting the animation.
        // TileView's flip task reads `state` at the midpoint; if we set the
        // colors here first (all in one SwiftUI publish batch with revealingRow)
        // the tile always sees the correct color — no async race condition.
        for col in 0..<5 {
            tileStates[row][col] = result[col]
        }

        // Start the staggered flip animation. Delays run right-to-left, so the
        // rightmost tile flips first and the reveal sweeps toward the left.
        revealDelays = (0..<5).map { Double(4 - $0) * 0.3 }
        revealingRow = row

        // Staggered per-tile feedback, fired at each flip's midpoint.
        if soundEnabled {
            for col in 0..<5 {
                let fireDelay = revealDelays[col] + 0.15
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(fireDelay * 1_000_000_000))
                    SoundManager.shared.reveal(result[col])
                }
            }
        }

        // After all flips complete (use the longest stagger, now the leftmost tile)
        let doneDelay = (revealDelays.max() ?? 0) + 0.3
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(doneDelay * 1_000_000_000))
            self.revealingRow = nil
            self.updateLetterStates(guess: guess, result: result)
            self.handleGuessResult(guess: guess, result: result, row: row)
        }
    }

    // MARK: - Hard Mode

    /// Returns an error message if `guess` violates Hard Mode rules, else nil.
    /// Rule: revealed greens must stay in position; revealed yellows must be reused.
    private func hardModeViolation(for guess: String) -> String? {
        guard hardMode, currentRow > 0 else { return nil }

        let guessChars = Array(guess)
        var greens: [Int: Character] = [:]      // position -> required letter
        var requiredPresent: Set<Character> = []

        for r in 0..<currentRow {
            let rowChars = Array(tiles[r].joined())
            for c in 0..<5 {
                switch tileStates[r][c] {
                case .correct: greens[c] = rowChars[c]
                case .present: requiredPresent.insert(rowChars[c])
                default:       break
                }
            }
        }

        // Greens must occupy the same position.
        for c in 0..<5 {
            if let req = greens[c], guessChars[c] != req {
                return "\(Self.ordinal(c + 1)) letter must be \(req)"
            }
        }
        // Yellows must appear somewhere in the guess.
        for ch in requiredPresent.sorted() where !guessChars.contains(ch) {
            return "Guess must contain \(ch)"
        }
        return nil
    }

    private static func ordinal(_ n: Int) -> String {
        switch n {
        case 1:  return "1st"
        case 2:  return "2nd"
        case 3:  return "3rd"
        default: return "\(n)th"
        }
    }

    // MARK: - Evaluation

    private func evaluate(guess: String, against secret: String) -> [TileState] {
        var result        = [TileState](repeating: .absent, count: 5)
        var secretChars   = Array(secret)
        var guessChars    = Array(guess)

        // Pass 1: correct positions
        for i in 0..<5 where guessChars[i] == secretChars[i] {
            result[i]       = .correct
            secretChars[i]  = "★"
            guessChars[i]   = "☆"
        }
        // Pass 2: present letters
        for i in 0..<5 where guessChars[i] != "☆" {
            if let j = secretChars.firstIndex(of: guessChars[i]) {
                result[i]      = .present
                secretChars[j] = "★"
            }
        }
        return result
    }

    private func updateLetterStates(guess: String, result: [TileState]) {
        let chars = Array(guess)
        for i in 0..<5 {
            let ch      = chars[i]
            let incoming = result[i].asLetterState
            let current  = letterStates[ch] ?? .unused
            if incoming > current { letterStates[ch] = incoming }
        }
    }

    private func handleGuessResult(guess: String, result: [TileState], row: Int) {
        if guess == secretWord {
            gameState    = .won
            showConfetti = true
            toast(WinMessage.message(forGuess: row + 1), duration: 3)
            recordResult(won: true, guessCount: row + 1)
            if soundEnabled { SoundManager.shared.win() }
            saveGame()
        } else {
            currentRow += 1
            currentCol  = 0
            if currentRow >= 6 {
                gameState = .lost
                toast(secretWord, duration: 8)
                recordResult(won: false, guessCount: 6)
                if soundEnabled { SoundManager.shared.lose() }
            }
            saveGame()
        }
    }

    // MARK: - Animations

    private func triggerShake(row: Int) {
        shakingRow = row
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            shakingRow = nil
        }
    }

    // MARK: - Toast

    func toast(_ message: String, duration: Double = 1.8) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            toastMessage = nil
        }
    }

    // MARK: - Share

    var dayLabel: String { "LetterLogic \(puzzleNumber)" }

    /// Number of guesses used. On a win, `currentRow` stays on the winning
    /// row index (0-based), so guesses used is `currentRow + 1`. On a loss the
    /// board is full, so 6.
    var guessesUsed: Int {
        gameState == .won ? currentRow + 1 : 6
    }

    func shareText() -> String {
        let guessLabel = gameState == .won ? "\(guessesUsed)/6" : "X/6"
        var text = "\(dayLabel) \(guessLabel)\n"
        let rows = guessesUsed
        for r in 0..<rows {
            text += "\n"
            for c in 0..<5 {
                switch tileStates[r][c] {
                case .correct: text += palette.correctEmoji
                case .present: text += palette.presentEmoji
                default:       text += "⬛"
                }
            }
        }
        return text
    }

    // MARK: - Statistics

    private func recordResult(won: Bool, guessCount: Int) {
        statistics.gamesPlayed += 1
        if won {
            statistics.gamesWon     += 1
            statistics.currentStreak += 1
            statistics.maxStreak     = max(statistics.maxStreak, statistics.currentStreak)
            let key = "\(guessCount)"
            statistics.guessDistribution[key, default: 0] += 1
        } else {
            statistics.currentStreak = 0
        }
        saveStatistics()
    }

    // MARK: - Persistence

    private let statsKey        = "letterlogic_statistics"
    private let legacyStatsKey  = "wordle_statistics"   // pre-rename key
    private let savedGameKey    = "ll_saved_game"
    private let usedAnswersKey  = "ll_used_answers"
    private let puzzleNumberKey = "ll_puzzle_number"

    private func loadStatistics() {
        let defaults = UserDefaults.standard
        // One-time migration: move stats saved under the old key to the new one.
        if defaults.data(forKey: statsKey) == nil,
           let legacy = defaults.data(forKey: legacyStatsKey) {
            defaults.set(legacy, forKey: statsKey)
            defaults.removeObject(forKey: legacyStatsKey)
        }
        guard let data = defaults.data(forKey: statsKey),
              let s    = try? JSONDecoder().decode(Statistics.self, from: data)
        else { return }
        statistics = s
    }

    private func saveStatistics() {
        guard let data = try? JSONEncoder().encode(statistics) else { return }
        UserDefaults.standard.set(data, forKey: statsKey)
    }

    private func saveGame() {
        let state = SavedGameState(
            tiles:           tiles,
            tileStates:      tileStates,
            currentRow:      currentRow,
            currentCol:      currentCol,
            gameState:       gameState,
            secretWord:      secretWord,
            isDaily:         false,
            letterStateRaw:  Dictionary(uniqueKeysWithValues:
                letterStates.map { (String($0.key), $0.value.rawValue) }
            )
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: savedGameKey)
    }

    /// Restores the last saved game (in-progress or finished), if any.
    /// Returns false (so the caller starts a fresh game) when no valid save
    /// exists or when the stored data is malformed.
    private func attemptRestoreGame() -> Bool {
        guard
            let data  = UserDefaults.standard.data(forKey: savedGameKey),
            let state = try? JSONDecoder().decode(SavedGameState.self, from: data)
        else { return false }

        // Defensive validation: the board views index a fixed rowCount × columnCount
        // grid, so a save with the wrong shape (corrupted data or an older format)
        // would crash on access. Reject it and fall back to a new game.
        let rows = Self.rowCount, cols = Self.columnCount
        guard state.tiles.count == rows,
              state.tileStates.count == rows,
              state.tiles.allSatisfy({ $0.count == cols }),
              state.tileStates.allSatisfy({ $0.count == cols }),
              (0..<rows).contains(state.currentRow),
              (0...cols).contains(state.currentCol)
        else { return false }

        secretWord   = state.secretWord
        tiles        = state.tiles
        tileStates   = state.tileStates
        currentRow   = state.currentRow
        currentCol   = state.currentCol
        gameState    = state.gameState
        letterStates = Dictionary(uniqueKeysWithValues:
            state.letterStateRaw.compactMap { key, val -> (Character, LetterState)? in
                guard let ch = key.first, let ls = LetterState(rawValue: val) else { return nil }
                return (ch, ls)
            }
        )
        return true
    }

    private func saveUsedAnswers() {
        UserDefaults.standard.set(Array(usedAnswers), forKey: usedAnswersKey)
    }

    private func loadUsedAnswers() {
        if let arr = UserDefaults.standard.array(forKey: usedAnswersKey) as? [String] {
            usedAnswers = Set(arr)
        }
    }

    // MARK: - Board Geometry

    /// Letters per word / tiles per row.
    static let columnCount = 5
    /// Number of guesses allowed / rows on the board.
    static let rowCount    = 6

    // MARK: - Helpers

    private static func blankBoardStrings() -> [[String]] {
        Array(repeating: Array(repeating: "", count: columnCount), count: rowCount)
    }
    private static func blankBoardStates() -> [[TileState]] {
        Array(repeating: Array(repeating: .empty, count: columnCount), count: rowCount)
    }
}

// MARK: - TileState → LetterState conversion

private extension TileState {
    var asLetterState: LetterState {
        switch self {
        case .correct: return .correct
        case .present: return .present
        case .absent:  return .absent
        default:       return .unused
        }
    }
}
