import SwiftUI

// MARK: - Granola-inspired Dark Olive Theme
enum Theme {
    // Backgrounds
    static let bgPrimary = Color(hex: "#1a1a17")
    static let bgSidebar = Color(hex: "#1a1a17")
    static let bgCard = Color(hex: "#2a2a24")
    static let bgCardBorder = Color(hex: "#3a3a32")
    static let bgHover = Color(hex: "#2a2a24")
    static let bgActive = Color(hex: "#333328")
    static let bgInput = Color(hex: "#242420")

    // Text
    static let textPrimary = Color(hex: "#e8e4d9")
    static let textSecondary = Color(hex: "#8a8678")
    static let textHeading = Color(hex: "#e8e4d9")
    static let textMuted = Color(hex: "#5a5850")

    // Accents
    static let accentGreen = Color(hex: "#6b8f5e")
    static let accentOrange = Color(hex: "#c4854a")
    static let accentYellow = Color(hex: "#b8a44a")
    static let accentBlue = Color(hex: "#4a7fb8")

    // Borders
    static let border = Color(hex: "#333328")
    static let divider = Color(hex: "#2a2a24")

    // Spacing
    static let paddingSM: CGFloat = 8
    static let paddingMD: CGFloat = 16
    static let paddingLG: CGFloat = 24
    static let paddingXL: CGFloat = 32

    // Corner radius
    static let radiusSM: CGFloat = 6
    static let radiusMD: CGFloat = 8
    static let radiusLG: CGFloat = 12
    static let radiusPill: CGFloat = 20

    // Sidebar
    static let sidebarWidth: CGFloat = 220
}

// MARK: - Fonts
extension Font {
    /// Serif font for headings — matches Granola's style
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, design: .serif)
    }

    /// Sans-serif body text
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func bodyMedium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }

    static func bodySemibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
