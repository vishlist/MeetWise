import SwiftUI

// MARK: - MeetWise Design System — Pastel Light Editorial Theme

enum Theme {
    // --- Backgrounds ---
    static let bgPrimary    = Color(hex: "#FAF8F5")    // warm off-white
    static let bgSidebar    = Color(hex: "#F3F0F8")    // light lavender
    static let bgCard       = Color(hex: "#FFFFFF")    // pure white
    static let bgCardBorder = Color(hex: "#E8E4F0")    // subtle lavender border
    static let bgHover      = Color(hex: "#F5F3F0")    // warm hover
    static let bgActive     = Color(hex: "#EDE8F4")    // lavender active
    static let bgInput      = Color(hex: "#FFFFFF")    // white input
    static let bgElevated   = Color(hex: "#F8F6FF")    // very light lavender tint

    // --- Text ---
    static let textPrimary   = Color(hex: "#1A1A2E")   // dark charcoal
    static let textSecondary = Color(hex: "#5A5A6A")   // medium gray
    static let textHeading   = Color(hex: "#1A1A2E")   // dark charcoal
    static let textMuted     = Color(hex: "#9A9AAA")   // light gray

    // --- Accents ---
    static let accent        = Color(hex: "#7C6BC4")   // muted purple
    static let accentGlow    = Color(hex: "#7C6BC4").opacity(0.10)
    static let accentGreen   = Color(hex: "#6BAF8D")   // soft green
    static let accentOrange  = Color(hex: "#C4956B")   // warm muted orange
    static let accentYellow  = Color(hex: "#B8A86B")   // muted gold
    static let accentBlue    = Color(hex: "#6B8FC4")   // soft blue
    static let accentPink    = Color(hex: "#C46B8F")   // soft rose
    static let accentRed     = Color(hex: "#C46B6B")   // soft red for errors

    // --- Pastels ---
    static let pastelLavender = Color(hex: "#E8E0F0")
    static let pastelBlue     = Color(hex: "#E0EBF5")
    static let pastelMint     = Color(hex: "#E0F2ED")
    static let pastelPeach    = Color(hex: "#F5E6E0")
    static let pastelYellow   = Color(hex: "#F5F0E0")
    static let pastelRose     = Color(hex: "#F5E0E8")

    static let pastelColors: [Color] = [
        pastelLavender, pastelBlue, pastelMint, pastelPeach, pastelYellow, pastelRose
    ]

    // --- Borders ---
    static let border  = Color(hex: "#E8E4F0")
    static let divider = Color(hex: "#EDE8F4")

    // --- Gradients ---
    static let gradientAccent = LinearGradient(
        colors: [Color(hex: "#7C6BC4"), Color(hex: "#9B8ED8")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradientCard = LinearGradient(
        colors: [Color.white, Color(hex: "#FAF8F5")],
        startPoint: .top, endPoint: .bottom
    )
    static let gradientGlow = RadialGradient(
        colors: [Color(hex: "#7C6BC4").opacity(0.06), .clear],
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
    static func glow(_ color: Color = Color(hex: "#7C6BC4"), radius: CGFloat = 12) -> some View {
        color.opacity(0.06).blur(radius: radius)
    }

    // --- Card shadow ---
    static func cardShadow() -> some ViewModifier {
        SoftShadow()
    }

    // --- Attendee colors (pastel tones) ---
    static let attendeeColors: [Color] = [
        Color(hex: "#7C6BC4"),
        Color(hex: "#6B8FC4"),
        Color(hex: "#6BAF8D"),
        Color(hex: "#C4956B"),
        Color(hex: "#C46B8F"),
        Color(hex: "#B8A86B"),
        Color(hex: "#8B6BC4"),
        Color(hex: "#6BC4A8"),
    ]
}

// MARK: - Fonts (Georgia serif for headings, system light for body)
extension Font {
    static func heading(_ size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size)
    }
    static func subheading(_ size: CGFloat) -> Font {
        .custom("Georgia", size: size)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light)
    }
    static func bodyMedium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }
    static func bodySemibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .monospaced)
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

// MARK: - Soft Shadow
struct SoftShadow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

extension View {
    func softShadow() -> some View {
        modifier(SoftShadow())
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
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
            .onHover { isHovering = $0 }
    }
}

// MARK: - Smooth Button Style (Purple bg, white text)
struct SmoothButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMD)
                    .fill(Theme.accent)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : (isHovering ? 1.01 : 1.0))
            .shadow(color: Theme.accent.opacity(isHovering ? 0.2 : 0), radius: 8, y: 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { isHovering = $0 }
    }
}

// MARK: - Glass Card (now white card with soft shadow)
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = Theme.radiusMD
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(Theme.bgCard))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
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
            .shadow(color: color.opacity(0.12), radius: radius, x: 0, y: 2)
    }
}

extension View {
    func glow(_ color: Color = Theme.accent, radius: CGFloat = 8) -> some View {
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
            .scaleEffect(isPressed ? 0.99 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
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
            .shadow(color: .black.opacity(isHovering ? 0.08 : 0.04), radius: isHovering ? 12 : 8, y: isHovering ? 4 : 2)
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

    init(_ text: String, icon: String? = nil, color: Color = Theme.accent) {
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
        .background(color.opacity(0.10))
        .cornerRadius(Theme.radiusPill)
    }
}

// MARK: - Collapsible Section (white card with shadow, Georgia header)
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
                        .foregroundStyle(Theme.accent)
                        .frame(width: 18)
                    Text(title)
                        .font(.custom("Georgia", size: 15))
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
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Stats Card (white bg, pastel icon tint, soft shadow)
struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    var pastelBg: Color = Theme.pastelBlue
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accent.opacity(0.6))
                    .padding(6)
                    .background(pastelBg.opacity(0.6))
                    .cornerRadius(6)
            }

            Text(value)
                .font(.custom("Georgia-Bold", size: 28))
                .foregroundStyle(Theme.textHeading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Attendee Pill (pastel colored circles)
struct AttendeePill: View {
    let name: String
    let color: Color
    let onRemove: (() -> Void)?
    @State private var isHovering = false

    init(name: String, color: Color = Theme.accent, onRemove: (() -> Void)? = nil) {
        self.name = name
        self.color = color
        self.onRemove = onRemove
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 18, height: 18)
                .overlay(
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(color)
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
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Tag Pill (rotating pastel colors)
struct TagPill: View {
    let text: String
    var colorIndex: Int = 0

    private var pillColor: Color {
        Theme.pastelColors[abs(text.hashValue) % Theme.pastelColors.count]
    }

    var body: some View {
        Text("#\(text)")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(pillColor)
            .cornerRadius(Theme.radiusPill)
    }
}

// MARK: - Action Item Row (white bg, soft dividers)
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
                    .foregroundStyle(isCompleted ? Theme.accentGreen : Theme.textMuted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(isCompleted ? Theme.textMuted : Theme.textPrimary)
                    .strikethrough(isCompleted)

                HStack(spacing: 8) {
                    if let assignee, !assignee.isEmpty {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.pastelLavender)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Text(String(assignee.prefix(1)).uppercased())
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(Theme.accent)
                                )
                            Text(assignee)
                                .font(.system(size: 11, weight: .light))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    if let deadline, !deadline.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "calendar")
                                .font(.system(size: 9))
                            Text(deadline)
                                .font(.system(size: 11, weight: .light))
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
                .fill(Theme.bgCard)
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
        case "completed": return Theme.accentGreen
        case "processing": return Theme.accentBlue
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
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.pastelLavender)
            .cornerRadius(Theme.radiusPill)
    }
}
