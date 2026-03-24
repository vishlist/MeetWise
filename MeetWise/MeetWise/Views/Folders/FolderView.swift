import SwiftUI
import SwiftData

struct FolderView: View {
    let folderID: UUID
    @Query private var allFolders: [Folder]

    private var folder: Folder? {
        allFolders.first { $0.id == folderID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let folder = folder {
                Text(folder.name)
                    .font(.heading(24))
                    .foregroundStyle(Theme.textHeading)
                    .padding(.top, 40)
                    .padding(.horizontal, 48)

                if let meetings = folder.meetings, !meetings.isEmpty {
                    List(meetings) { meeting in
                        HStack {
                            Text(meeting.title)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(meeting.formattedDate)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .listRowBackground(Theme.bgCard)
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "folder")
                                .font(.system(size: 36))
                                .foregroundStyle(Theme.textMuted)
                            Text("No meetings in this folder")
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                Text("Folder not found")
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }
}
