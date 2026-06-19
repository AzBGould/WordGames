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
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

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
        .frame(width: width, height: height)
        .accessibilityLabel(label == "⌫" ? "Backspace" : label)
    }
}

// MARK: - Full Keyboard

struct KeyboardView: View {
    @ObservedObject var game: LetterLogicGame

    // Layout constants. Widths are computed from the available width so the
    // keyboard fits every device down to the narrowest iOS 16 phones (~360pt)
    // without clipping; wide keys (ENTER, ⌫) are 1.5× a letter key.
    private let keySpacing: CGFloat   = 6
    private let rowSpacing: CGFloat   = 8
    private let sidePadding: CGFloat  = 6
    private let keyHeight: CGFloat    = 58
    private let topRowKeyCount        = 10   // the widest row sets the unit size
    private let wideKeyFactor: CGFloat = 1.5

    var body: some View {
        GeometryReader { geo in
            // Unit (letter-key) width is set by the 10-key top row; every other
            // row uses the same unit and therefore fits comfortably.
            let available = geo.size.width - sidePadding * 2
            let unit = max(0, (available - keySpacing * CGFloat(topRowKeyCount - 1))
                              / CGFloat(topRowKeyCount))

            VStack(spacing: rowSpacing) {
                ForEach(keyRows.indices, id: \.self) { rowIdx in
                    HStack(spacing: keySpacing) {
                        ForEach(keyRows[rowIdx], id: \.self) { key in
                            KeyButton(
                                label:       key,
                                letterState: state(for: key),
                                palette:     game.palette,
                                dark:        game.darkTheme,
                                width:       keyWidth(for: key, unit: unit),
                                height:      keyHeight
                            ) {
                                handleKey(key)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, sidePadding)
        }
        .frame(height: keyHeight * 3 + rowSpacing * 2)
    }

    /// Letter keys are one unit; ENTER and ⌫ are 1.5 units.
    private func keyWidth(for key: String, unit: CGFloat) -> CGFloat {
        (key == "ENTER" || key == "⌫") ? unit * wideKeyFactor : unit
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
