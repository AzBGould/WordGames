import SwiftUI

// MARK: - Keyboard Layout

private let keyRows: [[String]] = [
    ["Q","W","E","R","T","Y","U","I","O","P"],
    ["A","S","D","F","G","H","J","K","L"],
    ["ENTER","Z","X","C","V","B","N","M","⌫"]
]

// MARK: - Key Button

struct KeyButton: View {
    let label: String
    let letterState: LetterState
    let palette: TilePalette
    let dark: Bool
    let action: () -> Void

    private var isWide: Bool { label == "ENTER" || label == "⌫" }

    private var background: Color {
        letterState.keyColor(dark: dark, palette: palette)
    }

    private var foreground: Color {
        letterState.keyTextColor(dark: dark)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(background)

                if label == "⌫" {
                    Image(systemName: "delete.backward")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(foreground)
                } else {
                    Text(label)
                        .font(.system(size: label.count > 1 ? 12 : 14, weight: .bold))
                        .foregroundStyle(foreground)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: keyWidth(label), height: 58)
        .accessibilityLabel(label == "⌫" ? "Backspace" : label)
    }

    private func keyWidth(_ label: String) -> CGFloat {
        switch label {
        case "ENTER": return 65
        case "⌫":    return 44
        default:      return 34
        }
    }
}

// MARK: - Full Keyboard

struct KeyboardView: View {
    @ObservedObject var game: LetterLogicGame

    var body: some View {
        VStack(spacing: 8) {
            ForEach(keyRows.indices, id: \.self) { rowIdx in
                HStack(spacing: 6) {
                    ForEach(keyRows[rowIdx], id: \.self) { key in
                        KeyButton(
                            label:        key,
                            letterState:  state(for: key),
                            palette:      game.palette,
                            dark:         game.darkTheme
                        ) {
                            handleKey(key)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Key state

    private func state(for key: String) -> LetterState {
        guard key.count == 1, let ch = key.first else { return .unused }
        return game.letterStates[ch] ?? .unused
    }

    // MARK: - Key action

    private func handleKey(_ key: String) {
        switch key {
        case "ENTER": game.submitGuess()
        case "⌫":    game.deleteLetter()
        default:      game.addLetter(key)
        }
    }
}
