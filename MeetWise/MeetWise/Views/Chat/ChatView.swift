import SwiftUI

struct ChatView: View {
    @State private var chatInput = ""
    @State private var selectedScope = "My notes"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Ask anything")
                    .font(.heading(32))
                    .foregroundStyle(Theme.textHeading)
                    .padding(.top, 40)

                // Chat input
                VStack(spacing: 0) {
                    // Scope tabs
                    HStack(spacing: 12) {
                        scopeTab("My notes", isSelected: selectedScope == "My notes")
                        scopeTab("All meetings", isSelected: selectedScope == "All meetings")
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Input field
                    HStack(spacing: 12) {
                        TextField("Transcribe a meeting to start asking questions", text: $chatInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Bottom toolbar
                    HStack(spacing: 12) {
                        Button { } label: {
                            Image(systemName: "paperclip")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)

                        Button { } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button { } label: {
                            Image(systemName: "mic")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusLG)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusLG)
                        .stroke(Theme.bgCardBorder, lineWidth: 1)
                )

                // Recipes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recipes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)

                    FlowLayout(spacing: 8) {
                        recipePill("List recent todos", color: Theme.accentGreen)
                        recipePill("Coach me Matt", color: Theme.accentGreen)
                        recipePill("Write weekly recap", color: Theme.accentOrange)
                        recipePill("Streamline my calendar", color: Theme.accentGreen)
                        recipePill("Blind spots", color: Theme.accentYellow)

                        Button { } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 11))
                                Text("See all")
                                    .font(.system(size: 13))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.bgCard)
                            .cornerRadius(Theme.radiusPill)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }

    private func scopeTab(_ title: String, isSelected: Bool) -> some View {
        Button {
            selectedScope = title
        } label: {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(Theme.textPrimary)
                            .frame(height: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func recipePill(_ title: String, color: Color) -> some View {
        Button { } label: {
            HStack(spacing: 6) {
                Text("/")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusPill)
        }
        .buttonStyle(.plain)
    }
}

// Simple flow layout for recipe pills
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
