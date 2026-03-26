import SwiftUI

// MARK: - MeetWise Design System — Warm Neutral "Ink on Paper" Theme

enum Theme {
    // --- Backgrounds ---
    static let bgPrimary    = Color(hex: "#F6F5F2")    // warm stone/paper
    static let bgSidebar    = Color(hex: "#EFEEE9")    // slightly darker warm gray
    static let bgCard       = Color(hex: "#FFFFFF")    // white
    static let bgCardBorder = Color(hex: "#E0DED8")    // warm gray border
    static let bgHover      = Color(hex: "#F0EFE9")    // warm hover
    static let bgActive     = Color(hex: "#E8E7E1")    // warm active
    static let bgInput      = Color(hex: "#FFFFFF")    // white input
    static let bgElevated   = Color(hex: "#F6F5F2")    // warm stone

    // --- Text ---
    static let textPrimary   = Color(hex: "#1C1C1E")   // near-black
    static let textSecondary = Color(hex: "#6B6B6B")   // medium gray
    static let textHeading   = Color(hex: "#1C1C1E")   // near-black
    static let textMuted     = Color(hex: "#A0A0A0")   // light gray

    // --- Accents (dark charcoal, no purple) ---
    static let accent        = Color(hex: "#2C2C2E")   // dark charcoal
    static let accentGlow    = Color(hex: "#2C2C2E").opacity(0.10)
    static let accentSoft    = Color(hex: "#E8E7E1")   // warm light gray for pills/badges
    static let accentGreen   = Color(hex: "#5A9B6B")   // muted forest green
    static let accentOrange  = Color(hex: "#B8955A")   // warm muted amber
    static let accentYellow  = Color(hex: "#B8A040")   // muted gold
    static let accentBlue    = Color(hex: "#6B8FA0")   // muted steel blue
    static let accentPink    = Color(hex: "#A06B7B")   // muted dusty rose
    static let accentRed     = Color(hex: "#C45A5A")   // muted red

    // --- Subtle Tints (barely-there, not bright pastels) ---
    static let tintWarm   = Color(hex: "#F0EAE0")   // very faint warm beige
    static let tintCool   = Color(hex: "#E8ECF0")   // very faint cool gray
    static let tintSage   = Color(hex: "#E8EDE8")   // barely-there sage
    static let tintAmber  = Color(hex: "#F0ECE0")   // faint amber

    static let tintColors: [Color] = [
        tintWarm, tintCool, tintSage, tintAmber
    ]

    // --- Status colors (muted) ---
    static let statusGreen  = Color(hex: "#5A9B6B")
    static let statusRed    = Color(hex: "#C45A5A")
    static let statusYellow = Color(hex: "#B8A040")

    // --- Borders ---
    static let border  = Color(hex: "#E0DED8")   // warm gray border
    static let divider = Color(hex: "#E8E6E0")   // slightly lighter

    // --- Gradients ---
    static let gradientAccent = LinearGradient(
        colors: [Color(hex: "#2C2C2E"), Color(hex: "#3C3C3E")],
        startPoint: .leading, endPoint: .trailing
    )
    static let gradientCard = LinearGradient(
        colors: [Color.white, Color(hex: "#F6F5F2")],
        startPoint: .top, endPoint: .bottom
    )
    static let gradientGlow = RadialGradient(
        colors: [Color(hex: "#2C2C2E").opacity(0.04), .clear],
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
    static func glow(_ color: Color = Color(hex: "#2C2C2E"), radius: CGFloat = 12) -> some View {
        color.opacity(0.04).blur(radius: radius)
    }

    // --- Card shadow ---
    static func cardShadow() -> some ViewModifier {
        SoftShadow()
    }

    // --- Attendee colors (neutral gray tones) ---
    static let attendeeColors: [Color] = [
        Color(hex: "#6B6B6B"),
        Color(hex: "#8B8B8B"),
        Color(hex: "#5A7B6B"),
        Color(hex: "#7B6B5A"),
        Color(hex: "#6B7B8B"),
        Color(hex: "#8B7B6B"),
        Color(hex: "#7B8B6B"),
        Color(hex: "#6B8B7B"),
    ]
}

// MARK: - Fonts (IBM Plex Serif for headings, system light for body)
extension Font {
    static func heading(_ size: CGFloat) -> Font {
        .custom("IBMPlexSerif-Bold", size: size)
    }
    static func subheading(_ size: CGFloat) -> Font {
        .custom("IBMPlexSerif-Regular", size: size)
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

// MARK: - Smooth Button Style (Dark charcoal bg, white text)
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
            .shadow(color: Theme.accent.opacity(isHovering ? 0.15 : 0), radius: 8, y: 2)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onHover { isHovering = $0 }
    }
}

// MARK: - Glass Card (white card with soft shadow)
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
            .shadow(color: color.opacity(0.08), radius: radius, x: 0, y: 2)
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

// MARK: - Collapsible Section (white card with warm shadow)
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
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 18)
                    Text(title)
                        .font(.custom("IBMPlexSerif-Bold", size: 15))
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

// MARK: - Stats Card (white bg, tint icon bg, soft shadow)
struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    var tintBg: Color = Theme.tintCool
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(6)
                    .background(tintBg)
                    .cornerRadius(6)
            }

            Text(value)
                .font(.custom("IBMPlexSerif-Bold", size: 28))
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

// MARK: - Attendee Pill (neutral gray circles)
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

// MARK: - Tag Pill (warm gray bg, dark text)
struct TagPill: View {
    let text: String
    var colorIndex: Int = 0

    private var pillColor: Color {
        Theme.accentSoft
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
                                .fill(Theme.accentSoft)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Text(String(assignee.prefix(1)).uppercased())
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(Theme.textSecondary)
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

// MARK: - Typing Indicator (3 animated dots) — Issue 6: Fixed animation
struct TypingIndicator: View {
    @State private var dot0Active = false
    @State private var dot1Active = false
    @State private var dot2Active = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Theme.textMuted)
                .frame(width: 6, height: 6)
                .offset(y: dot0Active ? -4 : 0)

            Circle()
                .fill(Theme.textMuted)
                .frame(width: 6, height: 6)
                .offset(y: dot1Active ? -4 : 0)

            Circle()
                .fill(Theme.textMuted)
                .frame(width: 6, height: 6)
                .offset(y: dot2Active ? -4 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                dot0Active = true
            }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.15)) {
                dot1Active = true
            }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(0.3)) {
                dot2Active = true
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
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.accentSoft)
            .cornerRadius(Theme.radiusPill)
    }
}
