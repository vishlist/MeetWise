import SwiftUI
import SwiftData

struct PeopleView: View {
    @Query(sort: \Contact.name) private var contacts: [Contact]
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedContact: Contact?
    @State private var askingAbout: Contact?
    @State private var personChatMessages: [(role: String, content: String)] = []
    @State private var personChatInput = ""

    private var filteredContacts: [Contact] {
        if searchText.isEmpty { return contacts }
        return contacts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.email?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main list
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("People")
                            .font(.heading(28))
                            .foregroundStyle(Theme.textHeading)
                        Spacer()
                        Text("\(contacts.count) contacts")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .padding(.top, 40)

                    // Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textMuted)
                        TextField("Search people...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .light))
                    }
                    .padding(10)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)

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

            // Person chat sidebar
            if let person = askingAbout {
                Divider().background(Theme.divider)
                personChatSidebar(person: person)
                    .frame(width: 320)
                    .transition(.move(edge: .trailing))
            }
        }
    }

    private func contactRow(_ contact: Contact) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { selectedContact = selectedContact?.id == contact.id ? nil : contact }
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Theme.tintCool)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(contact.initials)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.accent)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        HStack(spacing: 8) {
                            if let email = contact.email {
                                Text(email)
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            if let company = contact.company {
                                Text("- \(company.name)")
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundStyle(Theme.textMuted)
                            }
                        }
                    }

                    Spacer()

                    // Ask about person button
                    Button {
                        withAnimation {
                            askingAbout = contact
                            personChatMessages = []
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("Ask")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accentSoft)
                        .cornerRadius(Theme.radiusPill)
                    }
                    .buttonStyle(.plain)

                    Text("\(contact.meetingCount) meetings")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Theme.textMuted)

                    if let lastMet = contact.lastMetAt {
                        Text(formatRelativeDate(lastMet))
                            .font(.system(size: 12, weight: .light))
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
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(meeting.formattedDate)
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundStyle(Theme.textMuted)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        if contactMeetings.count > 5 {
                            Text("+ \(contactMeetings.count - 5) more")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Theme.textMuted)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom, 8)
                    .background(Theme.bgPrimary.opacity(0.5))
                } else {
                    Text("No meetings found with this contact")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Theme.textMuted)
                        .padding(12)
                }
            }
        }
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Person Chat Sidebar
    private func personChatSidebar(person: Contact) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Ask about \(person.name)")
                    .font(.custom("InstrumentSerif-Regular", size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Button { withAnimation { askingAbout = nil } } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            Divider().background(Theme.divider)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if personChatMessages.isEmpty {
                        Text("Ask about interactions with \(person.name)")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Theme.textMuted)
                            .padding(12)
                    }

                    ForEach(Array(personChatMessages.enumerated()), id: \.offset) { _, msg in
                        VStack(alignment: msg.role == "user" ? .trailing : .leading) {
                            Text(msg.content)
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(10)
                                .background(msg.role == "user" ? Theme.accentSoft.opacity(0.4) : Theme.bgCard)
                                .cornerRadius(Theme.radiusMD)
                                .shadow(color: msg.role == "assistant" ? Color.black.opacity(0.03) : .clear, radius: 3, y: 1)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: msg.role == "user" ? .trailing : .leading)
                    }

                    if appState.chatService.isLoading {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("Thinking...").font(.system(size: 12, weight: .light)).foregroundStyle(Theme.textMuted)
                        }
                        .padding(10)
                    }
                }
                .padding(12)
            }

            Divider().background(Theme.divider)

            HStack(spacing: 8) {
                TextField("Ask about \(person.name)...", text: $personChatInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .light))
                    .onSubmit { sendPersonChat(person: person) }

                Button { sendPersonChat(person: person) } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(personChatInput.isEmpty ? Theme.textMuted : Theme.accent)
                }
                .buttonStyle(.plain)
                .disabled(personChatInput.isEmpty)
            }
            .padding(12)
        }
        .background(Theme.bgPrimary)
    }

    private func sendPersonChat(person: Contact) {
        guard !personChatInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let question = personChatInput
        personChatInput = ""
        personChatMessages.append((role: "user", content: question))

        Task {
            let response = await appState.chatService.askAboutPerson(
                question,
                personName: person.name,
                meetings: meetings
            )
            personChatMessages.append((role: "assistant", content: response))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textMuted)
            Text("No contacts yet")
                .font(.custom("InstrumentSerif-Regular", size: 14))
                .foregroundStyle(Theme.textSecondary)
            Text("People from your meetings will appear here")
                .font(.system(size: 12, weight: .light))
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
