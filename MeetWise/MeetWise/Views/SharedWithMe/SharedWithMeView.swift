import SwiftUI

struct SharedWithMeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Shared with me")
                .font(.heading(28))
                .foregroundStyle(Theme.textHeading)

            Text("Notes that others have shared with you will appear here.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.textSecondary)

            // Empty state illustration
            VStack(spacing: 16) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent.opacity(0.4))

                Text("No shared notes yet")
                    .font(.custom("InstrumentSerif-Regular", size: 16))
                    .foregroundStyle(Theme.textPrimary)

                Text("When someone shares a note with you, it will show up here")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusLG)
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)

            Spacer()
        }
        .padding(.horizontal, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }
}
