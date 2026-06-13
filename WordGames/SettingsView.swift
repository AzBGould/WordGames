import SwiftUI

struct SettingsView: View {
    @ObservedObject var game: WordleGame
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.wordleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("SETTINGS")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                            .font(.system(size: 18))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider().background(Color.wordleHeaderLine)

                // Toggles
                VStack(spacing: 0) {
                    SettingRow(
                        title:    "Hard Mode",
                        subtitle: "Any revealed hints must be used in subsequent guesses",
                        isOn:     Binding(
                            get: { game.hardMode },
                            set: { game.hardMode = $0 }
                        )
                    )
                    Divider().background(Color.wordleHeaderLine).padding(.horizontal)

                    SettingRow(
                        title:    "Dark Theme",
                        subtitle: "Always on",
                        isOn:     .constant(true)
                    )
                    .disabled(true)

                    Divider().background(Color.wordleHeaderLine).padding(.horizontal)

                    SettingRow(
                        title:    "Color Blind Mode",
                        subtitle: "High contrast colors for improved color vision",
                        isOn:     Binding(
                            get: { game.highContrast },
                            set: { game.highContrast = $0 }
                        )
                    )

                    Divider().background(Color.wordleHeaderLine).padding(.horizontal)

                    SettingRow(
                        title:    "Sound Effects",
                        subtitle: "Play sounds on tile reveal",
                        isOn:     Binding(
                            get: { game.soundEnabled },
                            set: { game.soundEnabled = $0 }
                        )
                    )
                }
                .padding(.top, 4)

                Spacer()

                // Version footer
                Text("Wordle Clone • Made with SwiftUI")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.wordleGray)
                    .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Setting Row

private struct SettingRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.wordleGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.wordleGreen)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
