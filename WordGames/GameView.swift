import SwiftUI

// MARK: - Main Game View

struct GameView: View {
    @ObservedObject var game: LetterLogicGame
    @Binding var showStats: Bool
    @Binding var showSettings: Bool

    var body: some View {
        ZStack {
            AppTheme.background(dark: game.darkTheme).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────
                headerView
                    .frame(height: 50)

                Divider().background(AppTheme.divider(dark: game.darkTheme))

                // ── Board ────────────────────────────────────────────
                GeometryReader { geo in
                    let boardSize = min(geo.size.width - 8, geo.size.height - 10)
                    BoardView(game: game)
                        .frame(width: boardSize, height: boardSize)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .layoutPriority(1)

                // ── Keyboard ─────────────────────────────────────────
                KeyboardView(game: game)
                    .padding(.bottom, 8)
            }

            // ── Toast ─────────────────────────────────────────────
            if let msg = game.toastMessage {
                ToastView(message: msg, dark: game.darkTheme)
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(10)
            }

            // ── Confetti ──────────────────────────────────────────
            ConfettiView(isActive: $game.showConfetti)
                .allowsHitTesting(false)
                .zIndex(5)
        }
        .onKeyPress(phases: .down) { press in
            handleHardwareKey(press)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.primaryText(dark: game.darkTheme))
            }
            .padding(.leading, 16)

            Spacer()

            Text("LETTERLOGIC")
                .font(.system(size: 26, weight: .heavy, design: .serif))
                .foregroundStyle(AppTheme.primaryText(dark: game.darkTheme))
                .kerning(1)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer()

            Button { showStats = true } label: {
                Image(systemName: "chart.bar")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.primaryText(dark: game.darkTheme))
            }
            .padding(.trailing, 16)
        }
    }

    // MARK: - Hardware Keyboard Support

    private func handleHardwareKey(_ press: KeyPress) -> KeyPress.Result {
        let char = press.characters.uppercased()
        if press.key == .return {
            game.submitGuess(); return .handled
        }
        if press.key == .delete {
            game.deleteLetter(); return .handled
        }
        if char.count == 1, let c = char.first, c.isLetter {
            game.addLetter(char); return .handled
        }
        return .ignored
    }
}

// MARK: - Toast

struct ToastView: View {
    let message: String
    let dark: Bool

    var body: some View {
        Text(message.uppercased())
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(AppTheme.toastText(dark: dark))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.toastBg(dark: dark))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 60)
    }
}
