import SwiftUI
import SwiftData

struct SearchOverlay: View {
    @Binding var isPresented: Bool
    @State private var query = ""
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @Query(sort: \Contact.name) private var contacts: [Contact]
    @Environment(AppState.self) private var appState

    // MARK: - Search Results

    private struct SearchResult: Identifiable {
        let id = UUID()
        let type: ResultType
        let title: String
        let subtitle: String
        let icon: String
        let meeting: Meeting?
        let contact: Contact?

        enum ResultType: String {
            case meeting = "Meetings"
            case transcript = "Transcripts"
            case note = "Notes"
            case contact = "People"
        }
    }

    private var searchResults: [SearchResult] {
        guard !query.isEmpty else {
            // Show recent meetings when no query
            return Array(meetings.prefix(5)).map { meeting in
                SearchResult(
                    type: .meeting,
                    title: meeting.title,
                    subtitle: "\(meeting.formattedDate) - \(meeting.formattedTime)",
                    icon: "doc.text",
                    meeting: meeting,
                    contact: nil
                )
            }
        }

        var results: [SearchResult] = []
        let q = query.lowercased()

        // Search meeting titles
        for meeting in meetings where meeting.title.localizedCaseInsensitiveContains(q) {
            results.append(SearchResult(
                type: .meeting,
                title: meeting.title,
                subtitle: "\(meeting.formattedDate) - \(meeting.formattedTime)",
                icon: "doc.text",
                meeting: meeting,
                contact: nil
            ))
        }

        // Search transcript text
        for meeting in meetings {
            if let transcript = meeting.transcriptRaw,
               transcript.localizedCaseInsensitiveContains(q),
               !results.contains(where: { $0.meeting?.id == meeting.id }) {
                let snippet = extractSnippet(from: transcript, query: q)
                results.append(SearchResult(
                    type: .transcript,
                    title: meeting.title,
                    subtitle: snippet,
                    icon: "waveform",
                    meeting: meeting,
                    contact: nil
                ))
            }
        }

        // Search user notes
        for meeting in meetings {
            if meeting.userNotes.localizedCaseInsensitiveContains(q),
               !results.contains(where: { $0.meeting?.id == meeting.id }) {
                let snippet = extractSnippet(from: meeting.userNotes, query: q)
                results.append(SearchResult(
                    type: .note,
                    title: meeting.title,
                    subtitle: snippet,
                    icon: "note.text",
                    meeting: meeting,
                    contact: nil
                ))
            }
        }

        // Search enhanced notes
        for meeting in meetings {
            if let enhanced = meeting.enhancedNotes,
               enhanced.localizedCaseInsensitiveContains(q),
               !results.contains(where: { $0.meeting?.id == meeting.id }) {
                let snippet = extractSnippet(from: enhanced, query: q)
                results.append(SearchResult(
                    type: .note,
                    title: meeting.title,
                    subtitle: snippet,
                    icon: "sparkles",
                    meeting: meeting,
                    contact: nil
                ))
            }
        }

        // Search contacts
        for contact in contacts where contact.name.localizedCaseInsensitiveContains(q) ||
                                      (contact.email?.localizedCaseInsensitiveContains(q) ?? false) {
            results.append(SearchResult(
                type: .contact,
                title: contact.name,
                subtitle: contact.email ?? "\(contact.meetingCount) meetings",
                icon: "person.fill",
                meeting: nil,
                contact: contact
            ))
        }

        return results
    }

    /// Group results by type
    private var groupedResults: [(String, [SearchResult])] {
        let grouped = Dictionary(grouping: searchResults) { $0.type.rawValue }
        let order = ["Meetings", "Transcripts", "Notes", "People"]
        return order.compactMap { key in
            guard let items = grouped[key], !items.isEmpty else { return nil }
            return (key, items)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search input
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)

                TextField("Search notes, people, companies...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Theme.textPrimary)

                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                }

                Text("ESC")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentSoft)
                    .cornerRadius(4)
            }
            .padding(16)

            Divider().background(Theme.divider)

            // Results grouped by type
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if searchResults.isEmpty {
                        Text("No results found")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(16)
                    } else {
                        ForEach(groupedResults, id: \.0) { group in
                            Text(query.isEmpty && group.0 == "Meetings" ? "Recent" : group.0)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textMuted)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 4)

                            ForEach(group.1) { result in
                                Button {
                                    handleResultTap(result)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: result.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(Theme.accent.opacity(0.6))
                                            .frame(width: 20)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.title)
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundStyle(Theme.textPrimary)
                                                .lineLimit(1)
                                            Text(result.subtitle)
                                                .font(.system(size: 12, weight: .light))
                                                .foregroundStyle(Theme.textSecondary)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        Text(result.type.rawValue)
                                            .font(.system(size: 10, weight: .light))
                                            .foregroundStyle(Theme.textMuted)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Theme.accentSoft.opacity(0.5))
                                            .cornerRadius(4)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.clear)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(HoverButtonStyle())
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
        }
        .frame(width: 540)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusLG)
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }

    // MARK: - Actions
    private func handleResultTap(_ result: SearchResult) {
        if let meeting = result.meeting {
            appState.selectedMeeting = meeting
        } else if result.contact != nil {
            appState.selectedNavItem = .people
            appState.selectedMeeting = nil
        }
        isPresented = false
    }

    // MARK: - Helpers
    private func extractSnippet(from text: String, query: String, contextLength: Int = 60) -> String {
        guard let range = text.range(of: query, options: .caseInsensitive) else {
            return String(text.prefix(80))
        }
        let center = text.distance(from: text.startIndex, to: range.lowerBound)
        let start = max(0, center - contextLength)
        let startIndex = text.index(text.startIndex, offsetBy: start)
        let endIndex = text.index(startIndex, offsetBy: min(contextLength * 2, text.distance(from: startIndex, to: text.endIndex)))
        var snippet = String(text[startIndex..<endIndex])
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
        if start > 0 { snippet = "..." + snippet }
        if endIndex < text.endIndex { snippet = snippet + "..." }
        return snippet
    }
}
