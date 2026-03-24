import SwiftUI

// MARK: - MeetWise Design System
// Dark theme with electric violet/blue accents, glassmorphism, and modern micro-interactions

enum Theme {
    // ─── Backgrounds ───
    static let bgPrimary    = Color(hex: "#0d0d12")    // deep midnight
    static let bgSidebar    = Color(hex: "#101018")    // slightly lighter sidebar
    static let bgCard       = Color(hex: "#16161f")    // card surface
    static let bgCardBorder = Color(hex: "#1f1f2e")    // subtle card border
    static let bgHover      = Color(hex: "#1a1a28")    // hover state
    static let bgActive     = Color(hex: "#1e1e30")    // active/selected state
    static let bgInput      = Color(hex: "#12121a")    // input fields
    static let bgElevated   = Color(hex: "#1a1a26")    // elevated surfaces

    // ─── Text ───
    static let textPrimary   = Color(hex: "#e8e8f0")   // primary text - cool white
    static let textSecondary = Color(hex: "#7a7a96")   // secondary - muted lavender
    static let textHeading   = Color(hex: "#f0f0ff")   // headings - bright white with blue tint
    static let textMuted     = Color(hex: "#44445a")   // muted text

    // ─── Accents ───
    static let accent        = Color(hex: "#7c5cfc")   // primary accent - electric violet
    static let accentGlow    = Color(hex: "#7c5cfc").opacity(0.3)  // glow effect
    static let accentGreen   = Color(hex: "#34d399")   // success - emerald
    static let accentOrange  = Color(hex: "#f59e0b")   // warning - amber
    static let accentYellow  = Color(hex: "#eab308")   // attention
    static let accentBlue    = Color(hex: "#3b82f6")   // info - blue
    static let accentPink    = Color(hex: "#ec4899")    // highlight - pink
    static let accentRed     = Color(hex: "#ef4444")    // danger

    // ─── Borders ───
    static let border  = Color(hex: "#1f1f30")
    static let divider = Color(hex: "#18182a")

    // ─── Gradients ───
    static let gradientAccent = LinearGradient(
        colors: [Color(hex: "#7c5cfc"), Color(hex: "#3b82f6")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradientCard = LinearGradient(
        colors: [Color(hex: "#16161f"), Color(hex: "#101018")],
        startPoint: .top, endPoint: .bottom
    )
    static let gradientGlow = RadialGradient(
        colors: [Color(hex: "#7c5cfc").opacity(0.15), .clear],
        center: .center, startRadius: 0, endRadius: 200
    )

    // ─── Spacing ───
    static let paddingSM: CGFloat = 8
    static let paddingMD: CGFloat = 16
    static let paddingLG: CGFloat = 24
    static let paddingXL: CGFloat = 32

    // ─── Corner Radius ───
    static let radiusSM:   CGFloat = 8
    static let radiusMD:   CGFloat = 12
    static let radiusLG:   CGFloat = 16
    static let radiusXL:   CGFloat = 20
    static let radiusPill: CGFloat = 100

    // ─── Sidebar ───
    static let sidebarWidth: CGFloat = 230

    // ─── Shadows ───
    static func glow(_ color: Color = accent, radius: CGFloat = 12) -> some View {
        color.opacity(0.2).blur(radius: radius)
    }
}

// MARK: - Fonts
extension Font {
    /// Modern heading font — SF Pro Rounded or similar
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    /// Subheading
    static func subheading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func bodyMedium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }

    static func bodySemibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, design: .monospaced)
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
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

// MARK: - Animated Hover Button Style
struct HoverButtonStyle: ButtonStyle {
    var hoverColor: Color = Theme.bgHover
    var pressColor: Color = Theme.bgActive
    var cornerRadius: CGFloat = Theme.radiusSM

    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(configuration.isPressed ? pressColor : (isHovering ? hoverColor : .clear))
                    .animation(.easeOut(duration: 0.15), value: isHovering)
                    .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

// MARK: - Glass Card Modifier
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = Theme.radiusMD
    var borderOpacity: Double = 0.08

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.bgCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Theme.radiusMD) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Glow Effect Modifier
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.1), radius: radius * 2, x: 0, y: 4)
    }
}

extension View {
    func glow(_ color: Color = Theme.accent, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Animated Hover View
struct HoverScale: ViewModifier {
    @State private var isHovering = false
    var scale: CGFloat = 1.02

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .onHover { isHovering = $0 }
    }
}

extension View {
    func hoverScale(_ scale: CGFloat = 1.02) -> some View {
        modifier(HoverScale(scale: scale))
    }
}

// MARK: - Pill Tag
struct PillTag: View {
    let text: String
    let icon: String?
    let color: Color

    init(_ text: String, icon: String? = nil, color: Color = Theme.accent) {
        self.text = text
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .cornerRadius(Theme.radiusPill)
    }
}
