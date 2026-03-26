import SwiftUI

// MARK: - MeetWise Design System — Monochrome Black & White

enum Theme {
    // --- Backgrounds ---
    static let bgPrimary    = Color(hex: "#0a0a0a")    // pure black
    static let bgSidebar    = Color(hex: "#0e0e0e")    // sidebar
    static let bgCard       = Color(hex: "#161616")    // card surface
    static let bgCardBorder = Color(hex: "#1e1e1e")    // subtle border
    static let bgHover      = Color(hex: "#1a1a1a")    // hover
    static let bgActive     = Color(hex: "#202020")    // selected
    static let bgInput      = Color(hex: "#111111")    // input fields
    static let bgElevated   = Color(hex: "#181818")    // elevated

    // --- Text ---
    static let textPrimary   = Color(hex: "#f0f0f0")   // white
    static let textSecondary = Color(hex: "#888888")   // gray
    static let textHeading   = Color(hex: "#ffffff")   // bright white
    static let textMuted     = Color(hex: "#4a4a4a")   // dark gray

    // --- Accents (all white/gray based) ---
    static let accent        = Color(hex: "#ffffff")   // white accent
    static let accentGlow    = Color.white.opacity(0.15)
    static let accentGreen   = Color(hex: "#ffffff")   // white (was green)
    static let accentOrange  = Color(hex: "#cccccc")   // light gray
    static let accentYellow  = Color(hex: "#aaaaaa")   // mid gray
    static let accentBlue    = Color(hex: "#dddddd")   // near white
    static let accentPink    = Color(hex: "#bbbbbb")   // gray
    static let accentRed     = Color(hex: "#ff4444")   // keep red for errors

    // --- Borders ---
    static let border  = Color(hex: "#2a2a2a")
    static let divider = Color(hex: "#161616")

    // --- Gradients ---
    static let gradientAccent = LinearGradient(
        colors: [Color.white, Color(hex: "#cccccc")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradientCard = LinearGradient(
        colors: [Color(hex: "#161616"), Color(hex: "#0e0e0e")],
        startPoint: .top, endPoint: .bottom
    )
    static let gradientGlow = RadialGradient(
        colors: [Color.white.opacity(0.06), .clear],
        center: .center, startRadius: 0, endRadius: 200
    )

    // --- Spacing ---
    static let paddingSM: CGFloat = 8
    static let paddingMD: CGFloat = 16
    static let paddingLG: CGFloat = 24
    static let paddingXL: CGFloat = 32

    // --- Corner Radius ---
    static let radiusSM:   CGFloat = 8
    static let radiusMD:   CGFloat = 12
    static let radiusLG:   CGFloat = 16
    static let radiusXL:   CGFloat = 20
    static let radiusPill: CGFloat = 100

    // --- Sidebar ---
    static let sidebarWidth: CGFloat = 230

    // --- Shadows ---
    static func glow(_ color: Color = .white, radius: CGFloat = 12) -> some View {
        color.opacity(0.08).blur(radius: radius)
    }
}

// MARK: - Fonts
extension Font {
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    static func subheading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
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

// MARK: - Color Hex
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

// MARK: - Hover Button Style
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
            )
            .scaleEffect(configuration.isPressed ? 0.98 : (isHovering ? 1.01 : 1.0))
            .brightness(isHovering ? 0.03 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { isHovering = $0 }
    }
}

// MARK: - Smooth Button Style (White bg, black text, hover/press)
struct SmoothButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMD)
                    .fill(Color.white)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : (isHovering ? 1.02 : 1.0))
            .brightness(isHovering ? 0.05 : 0)
            .shadow(color: .white.opacity(isHovering ? 0.1 : 0), radius: 8, y: 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { isHovering = $0 }
    }
}

// MARK: - Glass Card
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = Theme.radiusMD
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(Theme.bgCard))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = Theme.radiusMD) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Glow
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.15), radius: radius, x: 0, y: 0)
    }
}

extension View {
    func glow(_ color: Color = .white, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Hover Scale
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

// MARK: - Hover Highlight
struct HoverHighlight: ViewModifier {
    @State private var isHovering = false
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusSM)
                    .fill(isHovering ? Theme.bgHover : .clear)
                    .opacity(isHovering ? 1 : 0)
            )
            .scaleEffect(isPressed ? 0.98 : (isHovering ? 1.01 : 1.0))
            .brightness(isHovering ? 0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onHover { isHovering = $0 }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func hoverHighlight() -> some View {
        modifier(HoverHighlight())
    }
}

// MARK: - Card Hover
struct CardHover: ViewModifier {
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMD)
                    .stroke(Color.white.opacity(isHovering ? 0.12 : 0), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isHovering ? 0.3 : 0.1), radius: isHovering ? 12 : 4, y: isHovering ? 4 : 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .onHover { isHovering = $0 }
    }
}

extension View {
    func cardHover() -> some View {
        modifier(CardHover())
    }
}

// MARK: - Pill Tag
struct PillTag: View {
    let text: String
    let icon: String?
    let color: Color

    init(_ text: String, icon: String? = nil, color: Color = .white) {
        self.text = text
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 10))
            }
            Text(text).font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .cornerRadius(Theme.radiusPill)
    }
}
