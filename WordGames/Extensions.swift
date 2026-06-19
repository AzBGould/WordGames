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

// MARK: - App Accent + Neutral Chrome Colors
// Original-design colors (no relation to any other word game's branding).

extension Color {
    static let appBackground = Color(hex: "121213")
    static let appAccent     = Color(hex: "2FA98E")  // brand teal (toggles, buttons)
    static let neutralGray   = Color(hex: "787C7E")
    static let neutralDark   = Color(hex: "3A3A3C")
}

// MARK: - Tile Palettes
// User-selectable color schemes for the result tiles. Each palette supplies
// the three feedback colors: `correct` (right letter, right spot),
// `present` (right letter, wrong spot), and `absent` (not in the word).
// All palettes are original choices, chosen to be visually distinct from one
// another and from any existing word game.

enum TilePalette: String, CaseIterable, Identifiable {
    case cool
    case warm
    case vibrant
    case accessible

    var id: String { rawValue }

    /// Title shown in the settings picker.
    var displayName: String {
        switch self {
        case .cool:       return "Cool"
        case .warm:       return "Warm"
        case .vibrant:    return "Vibrant"
        case .accessible: return "Color Blind"
        }
    }

    /// One-line description shown under the title.
    var subtitle: String {
        switch self {
        case .cool:       return "Teal & indigo — calm and modern"
        case .warm:       return "Terracotta & amber — earthy tones"
        case .vibrant:    return "Emerald & magenta — bold and bright"
        case .accessible: return "Orange & blue — high contrast for color vision"
        }
    }

    /// Right letter, right position.
    var correct: Color {
        switch self {
        case .cool:       return Color(hex: "2FA98E")  // teal
        case .warm:       return Color(hex: "C96A3F")  // terracotta
        case .vibrant:    return Color(hex: "18BC6B")  // emerald
        case .accessible: return Color(hex: "F5793A")  // orange
        }
    }

    /// Right letter, wrong position.
    var present: Color {
        switch self {
        case .cool:       return Color(hex: "6B7FD7")  // indigo / periwinkle
        case .warm:       return Color(hex: "E0A23C")  // amber
        case .vibrant:    return Color(hex: "E84D8A")  // magenta
        case .accessible: return Color(hex: "85C0F9")  // light blue
        }
    }

    /// Letter not in the word.
    var absent: Color {
        switch self {
        case .cool:       return Color(hex: "6B7280")  // slate gray
        case .warm:       return Color(hex: "8C8178")  // warm taupe
        case .vibrant:    return Color(hex: "5B5F6B")  // cool dark gray
        case .accessible: return Color(hex: "787C7E")  // neutral gray
        }
    }

    /// Emoji squares used in the shareable result grid.
    var correctEmoji: String {
        switch self {
        case .cool:       return "🟦"
        case .warm:       return "🟧"
        case .vibrant:    return "🟩"
        case .accessible: return "🟧"
        }
    }
    var presentEmoji: String {
        switch self {
        case .cool:       return "🟪"
        case .warm:       return "🟨"
        case .vibrant:    return "🟪"
        case .accessible: return "🟦"
        }
    }
}

// MARK: - App Theme (light / dark appearance)
// The tile feedback colors come from the user-selected `TilePalette` and are
// identical in both appearances; what changes here is the chrome: background,
// text, borders, dividers, and key colors.

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
    func backgroundColor(palette: TilePalette) -> Color {
        switch self {
        case .empty, .filled: return .clear
        case .correct: return palette.correct
        case .present: return palette.present
        case .absent:  return palette.absent
        }
    }

    func borderColor(dark: Bool, palette: TilePalette) -> Color {
        switch self {
        case .empty:  return AppTheme.emptyBorder(dark: dark)
        case .filled: return AppTheme.filledBorder(dark: dark)
        case .correct: return palette.correct
        case .present: return palette.present
        case .absent:  return palette.absent
        }
    }

    /// Letter color: dark/near-black on blank or filled tiles, white once a
    /// tile is colored in by any palette (the fill colors read the same in
    /// both light and dark appearance).
    func textColor(dark: Bool) -> Color {
        switch self {
        case .empty, .filled: return AppTheme.primaryText(dark: dark)
        case .correct, .present, .absent: return .white
        }
    }
}

// MARK: - LetterState → Key Color

extension LetterState {
    func keyColor(dark: Bool, palette: TilePalette) -> Color {
        switch self {
        case .unused:  return AppTheme.keyDefaultBg(dark: dark)
        case .absent:  return dark ? .neutralDark : .neutralGray
        case .present: return palette.present
        case .correct: return palette.correct
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
