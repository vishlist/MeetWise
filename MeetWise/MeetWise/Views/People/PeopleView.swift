import SwiftUI
import SwiftData

struct PeopleView: View {
    @Query(sort: \Contact.name) private var contacts: [Contact]
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedContact: Contact?

    private var filteredContacts: [Contact] {
        if searchText.isEmpty { return contacts }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("People")
                    .font(.heading(28))
                    .foregroundStyle(Theme.textHeading)
                    .padding(.top, 40)

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted)
                    TextField("Search people...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                }
                .padding(10)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)

                if filteredContacts.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredContacts) { contact in
                        contactRow(contact)
                    }
                }
            }
            .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }

    private func contactRow(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { selectedContact = selectedContact?.id == contact.id ? nil : contact }
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Theme.accentGreen)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(contact.initials)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        HStack(spacing: 8) {
                            if let email = contact.email {
                                Text(email)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            if let company = contact.company {
                                Text("· \(company.name)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }

                    Spacer()

                    Text("\(contact.meetingCount) meetings")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)

                    if let lastMet = contact.lastMetAt {
                        Text(formatRelativeDate(lastMet))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                    }

                    Image(systemName: selectedContact?.id == contact.id ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded: show meetings with this contact
            if selectedContact?.id == contact.id {
                let contactMeetings = meetings.filter { meeting in
                    meeting.participants?.contains(where: { $0.name == contact.name }) ?? false
                }
                if !contactMeetings.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(contactMeetings.prefix(5)) { meeting in
                            Button { appState.selectedMeeting = meeting } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textMuted)
                                    Text(meeting.title)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(meeting.formattedDate)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textMuted)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 8)
                    .background(Theme.bgCard.opacity(0.3))
                }
            }
        }
        .background(Theme.bgCard.opacity(0.3))
        .cornerRadius(Theme.radiusMD)
    }

    private var emptyState: some View {
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
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "yesterday" }
        if days < 7 { return "\(days)d ago" }
        return "\(days / 7)w ago"
    }
}
