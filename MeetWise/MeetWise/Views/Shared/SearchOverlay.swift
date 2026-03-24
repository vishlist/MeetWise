import SwiftUI
import SwiftData

struct SearchOverlay: View {
    @Binding var isPresented: Bool
    @State private var query = ""
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @Environment(AppState.self) private var appState

    private var filteredMeetings: [Meeting] {
        guard !query.isEmpty else { return Array(meetings.prefix(5)) }
        return meetings.filter { meeting in
            meeting.title.localizedCaseInsensitiveContains(query) ||
            (meeting.transcriptRaw?.localizedCaseInsensitiveContains(query) ?? false) ||
            (meeting.userNotes.localizedCaseInsensitiveContains(query))
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
                    .font(.system(size: 15))
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
                    .background(Theme.bgCard)
                    .cornerRadius(4)
            }
            .padding(16)

            Divider().background(Theme.divider)

            // Results
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    if filteredMeetings.isEmpty {
                        Text("No results found")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(16)
                    } else {
                        Text(query.isEmpty ? "Recent" : "Results")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 4)

                        ForEach(filteredMeetings) { meeting in
                            Button {
                                appState.selectedMeeting = meeting
                                isPresented = false
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.textMuted)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(meeting.title)
                                            .font(.system(size: 14))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text(meeting.formattedDate + " · " + meeting.formattedTime)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.textSecondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 500)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLG)
                .stroke(Theme.bgCardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }
}
