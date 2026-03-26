import SwiftUI

// MARK: - MeetWise Design System — Monochrome Dark Theme

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

    // --- Attendee colors (subtle, for telling people apart) ---
    static let attendeeColors: [Color] = [
        Color(hex: "#666666"),
        Color(hex: "#777777"),
        Color(hex: "#555555"),
        Color(hex: "#888888"),
        Color(hex: "#999999"),
        Color(hex: "#6a6a6a"),
        Color(hex: "#7a7a7a"),
        Color(hex: "#5a5a5a"),
    ]
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

// MARK: - Collapsible Section
struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    @State private var isExpanded: Bool
    let content: () -> Content

    init(title: String, icon: String, defaultExpanded: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self._isExpanded = State(initialValue: defaultExpanded)
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 18)
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMD)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Stats Card
struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textMuted)
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textHeading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMD)
                .stroke(isHovering ? Color.white.opacity(0.1) : Theme.border, lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Attendee Pill
struct AttendeePill: View {
    let name: String
    let color: Color
    let onRemove: (() -> Void)?
    @State private var isHovering = false

    init(name: String, color: Color = Theme.textSecondary, onRemove: (() -> Void)? = nil) {
        self.name = name
        self.color = color
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 18, height: 18)
                .overlay(
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.bgPrimary)
                )

            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textPrimary)

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0.5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusPill)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusPill)
                .stroke(Theme.border, lineWidth: 1)
        )
        .onHover { isHovering = $0 }
    }
}

// MARK: - Tag Pill
struct TagPill: View {
    let text: String

    var body: some View {
        Text("#\(text)")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(hex: "#2a2a2a"))
            .cornerRadius(Theme.radiusPill)
    }
}

// MARK: - Action Item Row
struct ActionItemRow: View {
    let task: String
    let assignee: String?
    let deadline: String?
    @State var isCompleted: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isCompleted.toggle() }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isCompleted ? Theme.textSecondary : Theme.textMuted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task)
                    .font(.system(size: 14))
                    .foregroundStyle(isCompleted ? Theme.textMuted : Theme.textPrimary)
                    .strikethrough(isCompleted)

                HStack(spacing: 8) {
                    if let assignee, !assignee.isEmpty {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.textMuted)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Text(String(assignee.prefix(1)).uppercased())
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(Theme.bgPrimary)
                                )
                            Text(assignee)
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    if let deadline, !deadline.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 9))
                            Text(deadline)
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Theme.textMuted)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusSM)
                .fill(Theme.bgCard.opacity(0.5))
        )
    }
}

// MARK: - Typing Indicator (3 animated dots)
struct TypingIndicator: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.textMuted)
                    .frame(width: 6, height: 6)
                    .offset(y: sin(phase + Double(index) * 0.8) * 4)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Status Dot
struct StatusDot: View {
    let status: String

    private var dotColor: Color {
        switch status {
        case "completed": return Color(hex: "#666666")
        case "processing": return Color(hex: "#888888")
        case "failed": return Theme.accentRed
        case "recording": return Theme.accentRed
        default: return Theme.textMuted
        }
    }

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: 6, height: 6)
    }
}

// MARK: - Count Badge
struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Theme.textMuted)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: "#2a2a2a"))
            .cornerRadius(Theme.radiusPill)
    }
}
