import SwiftUI

// MARK: - Single Tile

struct TileView: View {
    let letter: String
    let state:  TileState
    let isRevealing: Bool   // true when this tile's row is mid-flip
    let revealDelay: Double // stagger delay within the row
    let palette: TilePalette
    let dark: Bool

    @State private var displayState: TileState = .empty
    @State private var flipScale: CGFloat = 1.0   // horizontal flip: 1 → 0 → 1 (x-axis)
    @State private var popScale: CGFloat = 1.0     // letter-entry bounce (y-axis)

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(displayState.backgroundColor(palette: palette))

                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(displayState.borderColor(dark: dark, palette: palette), lineWidth: 2)

                if !letter.isEmpty {
                    Text(letter)
                        .font(.system(size: size * 0.52, weight: .bold, design: .default))
                        .foregroundStyle(displayState.textColor(dark: dark))
                        .minimumScaleFactor(0.5)
                        .accessibilityLabel(letter)
                }
            }
            // Flip folds horizontally (x-axis); the entry pop bounces vertically (y-axis).
            .scaleEffect(x: flipScale, y: popScale)
        }
        .aspectRatio(1, contentMode: .fit)
        // Animate flip when row is being revealed
        .onChange(of: isRevealing) { _, revealing in
            if revealing {
                animateFlip()
            }
        }
        // Bounce-in when letter is added
        .onChange(of: letter) { old, new in
            if !new.isEmpty && state == .filled {
                animatePop()
            } else if new.isEmpty {
                displayState = .empty
            }
        }
        // Sync initial state (e.g. restoring saved game)
        .onAppear {
            displayState = state
        }
    }

    // MARK: - Flip Animation

    private func animateFlip() {
        // Capture target color NOW (synchronously) before entering the Task.
        // The game already wrote the evaluated TileState to `state` before
        // setting revealingRow, so this value is guaranteed to be correct.
        let targetState = state

        // Scale X to 0 (fold along the vertical axis → horizontal flip)
        withAnimation(.easeIn(duration: 0.15).delay(revealDelay)) {
            flipScale = 0
        }
        // At the midpoint swap to the evaluated color, then unfold
        Task {
            try? await Task.sleep(nanoseconds: UInt64((revealDelay + 0.15) * 1_000_000_000))
            displayState = targetState
            withAnimation(.easeOut(duration: 0.15)) {
                flipScale = 1.0
            }
        }
    }

    // MARK: - Pop Animation (letter added)

    private func animatePop() {
        displayState = .filled
        withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) {
            popScale = 1.1
        }
        withAnimation(.spring(response: 0.1, dampingFraction: 0.4).delay(0.1)) {
            popScale = 1.0
        }
    }
}

// MARK: - Board Row

struct BoardRowView: View {
    let row: Int
    let tiles: [String]
    let states: [TileState]
    let isShaking: Bool
    let isRevealing: Bool
    let revealDelays: [Double]
    let palette: TilePalette
    let dark: Bool

    @State private var shakeValue: CGFloat = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<5, id: \.self) { col in
                TileView(
                    letter:      tiles[col],
                    state:       states[col],
                    isRevealing: isRevealing,
                    revealDelay: isRevealing ? revealDelays[col] : 0,
                    palette:     palette,
                    dark:        dark
                )
            }
        }
        .modifier(ShakeEffect(animatableData: shakeValue))
        .onChange(of: isShaking) { _, shaking in
            if shaking {
                withAnimation(.default) { shakeValue = 1 }
                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    shakeValue = 0
                }
            }
        }
    }
}

// MARK: - Full Board Grid

struct BoardView: View {
    @ObservedObject var game: LetterLogicGame

    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<6, id: \.self) { row in
                BoardRowView(
                    row:          row,
                    tiles:        game.tiles[row],
                    states:       game.tileStates[row],
                    isShaking:    game.shakingRow == row,
                    isRevealing:  game.revealingRow == row,
                    revealDelays: game.revealDelays,
                    palette:      game.palette,
                    dark:         game.darkTheme
                )
            }
        }
        .padding(.horizontal, 4)
    }
}
