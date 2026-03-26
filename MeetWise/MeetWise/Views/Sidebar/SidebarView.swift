import SwiftUI
import SwiftData

struct SidebarView: View {
    var sessionManager: MeetingSessionManager
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.position) private var folders: [Folder]
    @State private var editingFolder: Folder?
    @State private var editingFolderName = ""
    @State private var showDeleteConfirm = false
    @State private var folderToDelete: Folder?

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Search bar
            searchBar
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Recording indicator
            if sessionManager.isRecording {
                recordingIndicator
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            // Meeting detection status
            if appState.showMeetingDetectionBanner,
               let detected = appState.meetingDetectionService.detectedMeeting,
               !sessionManager.isRecording {
                detectionIndicator(detected)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }

            // Main nav items
            VStack(spacing: 2) {
                navItem(icon: "house.fill", label: "Home", item: .home)
                navItem(icon: "shared.with.you", label: "Shared with me", item: .sharedWithMe)
                navItem(icon: "bubble.left.and.bubble.right.fill", label: "Chat", item: .chat)
            }
            .padding(.horizontal, 8)

            Rectangle()
                .fill(Theme.divider)
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            // Spaces
            VStack(alignment: .leading, spacing: 2) {
                Text("SPACES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                    .tracking(1.2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                spaceSection(name: "My notes", icon: "lock.fill", isPersonal: true)
                spaceSection(name: "Vishal HQ", icon: "person.3.fill", isPersonal: false)
            }
            .padding(.horizontal, 8)

            Spacer()

            // Bottom section
            bottomSection
        }
        .background(Theme.bgSidebar)
        .alert("Delete Folder?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { folderToDelete = nil }
            Button("Delete", role: .destructive) {
                if let folder = folderToDelete {
                    modelContext.delete(folder)
                    try? modelContext.save()
                    folderToDelete = nil
                }
            }
        } message: {
            Text("This will remove the folder but not the meetings inside it.")
        }
    }

    // MARK: - Recording Indicator
    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .shadow(color: .red.opacity(0.5), radius: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(sessionManager.currentMeeting?.title ?? "Recording")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(sessionManager.formattedDuration)
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            // Mini waveform
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.red.opacity(0.6))
                        .frame(width: 2, height: max(3, CGFloat(sessionManager.audioLevel) * 12 * CGFloat(abs(sin(Double(i) * 0.7)))))
                }
            }
        }
        .padding(8)
        .background(Color.red.opacity(0.08))
        .cornerRadius(Theme.radiusSM)
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Color.red.opacity(0.2), lineWidth: 1))
        .onTapGesture {
            if let meeting = sessionManager.currentMeeting {
                appState.selectedMeeting = meeting
            }
        }
    }

    // MARK: - Detection Indicator
    private func detectionIndicator(_ detected: MeetingDetectionService.DetectedMeeting) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "video.fill")
                .font(.system(size: 10))
                .foregroundStyle(Theme.accent)

            Text(detected.platform.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)

            Spacer()

            Circle()
                .fill(Theme.accent)
                .frame(width: 5, height: 5)
        }
        .padding(8)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusSM)
    }

    private var searchBar: some View {
        Button {
            appState.isSearchPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted)
                Text("Search")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted)
                Spacer()
                Text("K")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.bgCard)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Theme.bgInput)
            .cornerRadius(Theme.radiusSM)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSM)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func navItem(icon: String, label: String, item: NavItem) -> some View {
        SidebarNavButton(
            icon: icon, label: label,
            isSelected: appState.selectedNavItem == item && appState.selectedMeeting == nil
        ) {
            appState.selectedNavItem = item
            appState.selectedMeeting = nil
        }
    }

    private func spaceSection(name: String, icon: String, isPersonal: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isPersonal ? Theme.accent : Theme.accent)
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            let spaceFolders = folders.filter { isPersonal ? $0.spaceType == "personal" : $0.spaceType == "team" }
            ForEach(spaceFolders) { folder in
                folderRow(folder)
                    .padding(.leading, 12)
            }

            Button {
                createFolder(isPersonal: isPersonal)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 10))
                    Text("Add folder").font(.system(size: 12))
                }
                .foregroundStyle(Theme.textMuted)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .padding(.leading, 12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Folder Row with Context Menu
    private func folderRow(_ folder: Folder) -> some View {
        Group {
            if editingFolder?.id == folder.id {
                // Inline rename
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 20)
                    TextField("Folder name", text: $editingFolderName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .onSubmit {
                            commitRename(folder)
                        }
                        .onExitCommand {
                            editingFolder = nil
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Theme.bgActive)
                .cornerRadius(Theme.radiusSM)
            } else {
                SidebarNavButton(
                    icon: "folder.fill", label: folder.name,
                    isSelected: appState.selectedNavItem == .folder(folder.id)
                ) {
                    appState.selectedNavItem = .folder(folder.id)
                    appState.selectedMeeting = nil
                }
                .contextMenu {
                    Button {
                        editingFolder = folder
                        editingFolderName = folder.name
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        folderToDelete = folder
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func createFolder(isPersonal: Bool) {
        let folder = Folder(name: "New Folder", spaceType: isPersonal ? "personal" : "team")
        folder.position = folders.count
        modelContext.insert(folder)
        try? modelContext.save()

        // Start editing immediately
        editingFolder = folder
        editingFolderName = folder.name
    }

    private func commitRename(_ folder: Folder) {
        let trimmed = editingFolderName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            folder.name = trimmed
            try? modelContext.save()
        }
        editingFolder = nil
    }

    private var bottomSection: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.divider).frame(height: 1).padding(.horizontal, 16)

            HStack(spacing: 0) {
                bottomIcon("gearshape.fill", item: .settings)
                bottomIcon("person.fill", item: .people)
                bottomIcon("building.2.fill", item: .companies)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            HStack {
                Text("Free Plan")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("Upgrade")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            HStack(spacing: 8) {
                Circle()
                    .fill(Theme.accent.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(appState.currentUser?.initials ?? "U")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.accent)
                    )
                Text(appState.currentUser?.fullName ?? "User")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func bottomIcon(_ icon: String, item: NavItem) -> some View {
        Button {
            appState.selectedNavItem = item
            appState.selectedMeeting = nil
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(appState.selectedNavItem == item ? Theme.accent : Theme.textMuted)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Animated Sidebar Nav Button
struct SidebarNavButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusSM)
                    .fill(isSelected ? Theme.accent.opacity(0.12) : (isHovering ? Theme.bgHover : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSM)
                    .stroke(isSelected ? Theme.accent.opacity(0.2) : .clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { isHovering = hovering }
        }
    }
}
