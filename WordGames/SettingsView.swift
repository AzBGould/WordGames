import SwiftUI

struct SettingsView: View {
    @ObservedObject var game: LetterLogicGame
    @Binding var isPresented: Bool

    // Sheet height is driven by the measured content height so the panel
    // opens fully without a partial detent or trailing white space.
    @State private var sheetHeight: CGFloat = 520

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

                    PalettePickerRow(
                        dark: dark,
                        selection: Binding(
                            get: { game.palette },
                            set: { game.palette = $0 }
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

                // Version footer
                Text("LetterLogic • Made with SwiftUI")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.secondaryText(dark: dark))
                    .padding(.top, 28)
                    .padding(.bottom, 24)
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SettingsHeightKey.self,
                                    value: proxy.size.height)
                }
            )
        }
        .onPreferenceChange(SettingsHeightKey.self) { height in
            if height > 0 { sheetHeight = height }
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Content Height Preference

private struct SettingsHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
                .tint(.appAccent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Palette Picker Row

private struct PalettePickerRow: View {
    let dark: Bool
    @Binding var selection: TilePalette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tile Colors")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.primaryText(dark: dark))
                Text("Choose the color scheme for your tiles")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.secondaryText(dark: dark))
            }

            ForEach(TilePalette.allCases) { palette in
                Button {
                    selection = palette
                } label: {
                    HStack(spacing: 12) {
                        // Color swatches
                        HStack(spacing: 4) {
                            swatch(palette.correct)
                            swatch(palette.present)
                            swatch(palette.absent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(palette.displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AppTheme.primaryText(dark: dark))
                            Text(palette.subtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.secondaryText(dark: dark))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Image(systemName: selection == palette
                              ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(selection == palette
                                             ? Color.appAccent
                                             : AppTheme.secondaryText(dark: dark))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selection == palette
                                  ? Color.appAccent.opacity(0.12)
                                  : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(selection == palette
                                          ? Color.appAccent
                                          : AppTheme.divider(dark: dark),
                                          lineWidth: selection == palette ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func swatch(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: 18, height: 18)
    }
}
