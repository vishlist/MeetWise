import SwiftUI

struct SharedWithMeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Shared with me")
                .font(.heading(28))
                .foregroundStyle(Theme.textHeading)

            Text("Notes that others have shared with you will appear here.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            // Empty state illustration
            VStack(spacing: 16) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.textMuted)

                Text("No shared notes yet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                Text("When someone shares a note with you, it will show up here")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(Theme.bgCard.opacity(0.3))
            .cornerRadius(Theme.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLG)
                    .stroke(Theme.bgCardBorder, style: StrokeStyle(lineWidth: 1, dash: [6]))
            )

            Spacer()
        }
        .padding(.horizontal, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }
}
