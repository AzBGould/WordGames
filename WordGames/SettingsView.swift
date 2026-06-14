import SwiftUI

struct SettingsView: View {
    @ObservedObject var game: WordleGame
    @Binding var isPresented: Bool

    private var dark: Bool { game.darkTheme }

    var body: some View {
        ZStack {
            AppTheme.background(dark: dark).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("SETTINGS")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText(dark: dark))
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppTheme.primaryText(dark: dark))
                            .font(.system(size: 18))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                Divider().background(AppTheme.divider(dark: dark))

                // Toggles
                VStack(spacing: 0) {
                    SettingRow(
                        title:    "Hard Mode",
                        subtitle: "Any revealed hints must be used in subsequent guesses",
                        dark:     dark,
                        isOn:     Binding(
                            get: { game.hardMode },
                            set: { game.hardMode = $0 }
                        )
                    )
                    Divider().background(AppTheme.divider(dark: dark)).padding(.horizontal)

                    SettingRow(
                        title:    "Dark Theme",
                        subtitle: "Switch between light and dark appearance",
                        dark:     dark,
                        isOn:     Binding(
                            get: { game.darkTheme },
                            set: { game.darkTheme = $0 }
                        )
                    )

                    Divider().background(AppTheme.divider(dark: dark)).padding(.horizontal)

                    SettingRow(
                        title:    "Color Blind Mode",
                        subtitle: "High contrast colors for improved color vision",
                        dark:     dark,
                        isOn:     Binding(
                            get: { game.highContrast },
                            set: { game.highContrast = $0 }
                        )
                    )

                    Divider().background(AppTheme.divider(dark: dark)).padding(.horizontal)

                    SettingRow(
                        title:    "Sound Effects",
                        subtitle: "Play sounds on tile reveal",
                        dark:     dark,
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
                    .foregroundStyle(AppTheme.secondaryText(dark: dark))
                    .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Setting Row

private struct SettingRow: View {
    let title: String
    let subtitle: String
    let dark: Bool
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.primaryText(dark: dark))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.secondaryText(dark: dark))
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
