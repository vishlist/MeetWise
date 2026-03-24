import SwiftUI
import SwiftData

struct PeopleView: View {
    @Query(sort: \Contact.name) private var contacts: [Contact]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("People")
                    .font(.heading(28))
                    .foregroundStyle(Theme.textHeading)
                    .padding(.top, 40)

                if contacts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.textMuted)
                        Text("No contacts yet")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                        Text("People from your meetings will appear here")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(contacts) { contact in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Theme.accentGreen)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(contact.initials)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.white)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                if let email = contact.email {
                                    Text(email)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                            Spacer()
                            Text("\(contact.meetingCount) meetings")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .padding(12)
                        .background(Theme.bgCard.opacity(0.3))
                        .cornerRadius(Theme.radiusMD)
                    }
                }
            }
            .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }
}
