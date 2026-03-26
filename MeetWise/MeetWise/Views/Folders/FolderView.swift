import SwiftUI
import SwiftData

struct FolderView: View {
    let folderID: UUID
    var sessionManager: MeetingSessionManager
    @Query private var allFolders: [Folder]
    @Query(sort: \Meeting.startedAt, order: .reverse) private var allMeetings: [Meeting]
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    private var folder: Folder? {
        allFolders.first { $0.id == folderID }
    }

    // Query all meetings and filter by folder — more reliable than relationship traversal
    private var folderMeetings: [Meeting] {
        allMeetings.filter { $0.folder?.id == folderID && (!$0.isDraft || $0.hasContent) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let folder = folder {
                // Header
                HStack {
                    Text(folder.name)
                        .font(.heading(24))
                        .foregroundStyle(Theme.textHeading)

                    Spacer()

                    Text("\(folderMeetings.count) notes")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.top, 40)
                .padding(.horizontal, 48)

                if !folderMeetings.isEmpty {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(folderMeetings) { meeting in
                                Button {
                                    appState.selectedMeeting = meeting
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: Theme.radiusSM)
                                                .fill(Theme.tintCool)
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "doc.text.fill")
                                                .font(.system(size: 15))
                                                .foregroundStyle(Theme.textMuted)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(meeting.title)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(Theme.textPrimary)
                                            Text(meeting.formattedDate + " " + meeting.formattedTime)
                                                .font(.system(size: 12, weight: .light))
                                                .foregroundStyle(Theme.textSecondary)
                                        }

                                        Spacer()

                                        if meeting.enhancedNotes != nil {
                                            PillTag("Enhanced", icon: "sparkles", color: Theme.textSecondary)
                                        }

                                        Text(meeting.formattedTime)
                                            .font(.mono(12))
                                            .foregroundStyle(Theme.textMuted)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: Theme.radiusMD)
                                            .fill(Theme.bgCard)
                                    )
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(HoverButtonStyle(cornerRadius: Theme.radiusMD))
                            }
                        }
                        .padding(.horizontal, 48)
                        .padding(.bottom, 40)
                    }
                } else {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "folder")
                                .font(.system(size: 36))
                                .foregroundStyle(Theme.accent.opacity(0.4))
                            Text("No meetings in this folder")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(Theme.textSecondary)
                            Text("Create a quick note or move existing notes here")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Theme.textMuted)

                            Button {
                                let meeting = sessionManager.startQuickNote(modelContext: modelContext, in: folder)
                                appState.selectedMeeting = meeting
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus").font(.system(size: 12))
                                    Text("Quick Note").font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Theme.accent)
                                .cornerRadius(Theme.radiusPill)
                            }
                            .buttonStyle(.plain)
                            .hoverScale(1.05)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                Text("Folder not found")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }
}
