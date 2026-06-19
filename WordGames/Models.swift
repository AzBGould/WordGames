import Foundation

// MARK: - Tile State

enum TileState: String, Codable, Equatable {
    case empty    // no letter entered
    case filled   // letter entered, not yet submitted
    case correct  // green: right letter, right position
    case present  // yellow: right letter, wrong position
    case absent   // gray: letter not in word
}

// MARK: - Game State

enum GameState: String, Codable, Equatable {
    case playing
    case won
    case lost
}

// MARK: - Keyboard Letter State

enum LetterState: Int, Comparable {
    case unused  = 0
    case absent  = 1
    case present = 2
    case correct = 3

    static func < (lhs: LetterState, rhs: LetterState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Statistics

struct Statistics: Codable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var currentStreak: Int = 0
    var maxStreak: Int = 0
    // Keyed by guess count as String for Codable compatibility
    var guessDistribution: [String: Int] = [
        "1": 0, "2": 0, "3": 0, "4": 0, "5": 0, "6": 0
    ]

    var winPercentage: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int(round(Double(gamesWon) / Double(gamesPlayed) * 100))
    }
}

// MARK: - Saved Game State (persistence)

struct SavedGameState: Codable {
    var tiles: [[String]]
    var tileStates: [[TileState]]
    var currentRow: Int
    var currentCol: Int
    var gameState: GameState
    var secretWord: String
    var isDaily: Bool
    var letterStateRaw: [String: Int]  // [letter: LetterState.rawValue]
}

// MARK: - Win Messages

enum WinMessage {
    static func message(forGuess guess: Int) -> String {
        switch guess {
        case 1: return "Genius"
        case 2: return "Magnificent"
        case 3: return "Impressive"
        case 4: return "Splendid"
        case 5: return "Great"
        default: return "Phew!"
        }
    }
}
