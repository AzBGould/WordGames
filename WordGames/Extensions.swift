import SwiftUI

// MARK: - Hex Color initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 255, 255, 255)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Wordle Brand Colors

extension Color {
    static let wordleBackground = Color(hex: "121213")
    static let wordleGreen      = Color(hex: "6AAA64")
    static let wordleYellow     = Color(hex: "C9B458")
    static let wordleGray       = Color(hex: "787C7E")
    static let wordleDarkGray   = Color(hex: "3A3A3C")
    static let wordleTileBorder = Color(hex: "3A3A3C")
    static let wordleTileFilled = Color(hex: "565758")
    static let wordleKeyBg      = Color(hex: "818384")
    static let wordleHeaderLine = Color(hex: "3A3A3C")
    static let wordleHighGreen  = Color(hex: "F5793A")  // high-contrast correct
    static let wordleHighYellow = Color(hex: "85C0F9")  // high-contrast present
}

// MARK: - App Theme (light / dark palette)
// Tile fill colors (green/yellow/gray) are the same in both themes; what
// changes is the chrome: background, text, borders, dividers, key colors.

enum AppTheme {
    static func background(dark: Bool) -> Color {
        dark ? Color(hex: "121213") : .white
    }
    static func primaryText(dark: Bool) -> Color {
        dark ? .white : Color(hex: "1A1A1B")
    }
    static func secondaryText(dark: Bool) -> Color {
        Color(hex: "787C7E")  // readable on both themes
    }
    static func divider(dark: Bool) -> Color {
        dark ? Color(hex: "3A3A3C") : Color(hex: "D3D6DA")
    }
    static func emptyBorder(dark: Bool) -> Color {
        dark ? Color(hex: "3A3A3C") : Color(hex: "D3D6DA")
    }
    static func filledBorder(dark: Bool) -> Color {
        dark ? Color(hex: "565758") : Color(hex: "878A8C")
    }
    static func keyDefaultBg(dark: Bool) -> Color {
        dark ? Color(hex: "818384") : Color(hex: "D3D6DA")
    }
    /// Gray fill for distribution bars and the secondary "New Game" button
    /// (always shows white text on top, so it stays a medium gray).
    static func grayFill(dark: Bool) -> Color {
        dark ? Color(hex: "3A3A3C") : Color(hex: "787C7E")
    }
    static func modePillBg(dark: Bool) -> Color {
        dark ? Color(hex: "3A3A3C") : Color(hex: "D3D6DA")
    }
    /// Toast inverts the background for contrast.
    static func toastBg(dark: Bool) -> Color {
        dark ? .white : Color(hex: "121213")
    }
    static func toastText(dark: Bool) -> Color {
        dark ? Color(hex: "121213") : .white
    }
}

// MARK: - TileState → Colors

extension TileState {
    func backgroundColor(highContrast: Bool) -> Color {
        switch self {
        case .empty, .filled: return .clear
        case .correct: return highContrast ? .wordleHighGreen  : .wordleGreen
        case .present: return highContrast ? .wordleHighYellow : .wordleYellow
        case .absent:  return .wordleGray
        }
    }

    func borderColor(dark: Bool, highContrast: Bool) -> Color {
        switch self {
        case .empty:  return AppTheme.emptyBorder(dark: dark)
        case .filled: return AppTheme.filledBorder(dark: dark)
        case .correct: return highContrast ? .wordleHighGreen  : .wordleGreen
        case .present: return highContrast ? .wordleHighYellow : .wordleYellow
        case .absent:  return .wordleGray
        }
    }

    /// Letter color: dark/near-black on blank or filled tiles, white once a
    /// tile is colored in (green/yellow/gray look the same in both themes).
    func textColor(dark: Bool) -> Color {
        switch self {
        case .empty, .filled: return AppTheme.primaryText(dark: dark)
        case .correct, .present, .absent: return .white
        }
    }
}

// MARK: - LetterState → Key Color

extension LetterState {
    func keyColor(dark: Bool, highContrast: Bool) -> Color {
        switch self {
        case .unused:  return AppTheme.keyDefaultBg(dark: dark)
        case .absent:  return dark ? .wordleDarkGray : .wordleGray
        case .present: return highContrast ? .wordleHighYellow : .wordleYellow
        case .correct: return highContrast ? .wordleHighGreen  : .wordleGreen
        }
    }

    /// Key label color: dark text on an unused light key, white otherwise.
    func keyTextColor(dark: Bool) -> Color {
        switch self {
        case .unused: return AppTheme.primaryText(dark: dark)
        default:      return .white
        }
    }
}

// MARK: - Shake Geometry Effect

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

// MARK: - Pop Scale Modifier (letter bounce-in)

struct PopScaleModifier: ViewModifier {
    var isPopped: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPopped ? 1.12 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.5), value: isPopped)
    }
}
