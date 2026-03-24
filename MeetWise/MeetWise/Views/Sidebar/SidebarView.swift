import SwiftUI
import SwiftData

struct SidebarView: View {
    var sessionManager: MeetingSessionManager
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Folder> { $0.spaceType == "personal" },
           sort: \Folder.position)
    private var personalFolders: [Folder]

    @Query(filter: #Predicate<Folder> { $0.spaceType == "team" },
           sort: \Folder.position)
    private var teamFolders: [Folder]

    @State private var isAddingPersonalFolder = false
    @State private var isAddingTeamFolder = false
    @State private var newFolderName = ""

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Search bar
            searchBar

            // Navigation items
            VStack(spacing: 2) {
                navItem(title: "Home", icon: "house", item: .home)
                navItem(title: "Shared with me", icon: "person.2", item: .sharedWithMe)
                navItem(title: "Chat", icon: "bubble.left", item: .chat)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Divider()
                .background(Theme.divider)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

            // Spaces
            VStack(alignment: .leading, spacing: 4) {
                Text("Spaces")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                // My notes (personal space)
                spaceSection(
                    title: "My notes",
                    icon: "lock.fill",
                    folders: personalFolders,
                    spaceType: "personal",
                    isAddingFolder: $isAddingPersonalFolder
                )

                // Team HQ
                spaceSection(
                    title: "Vishal HQ",
                    icon: "person.3.fill",
                    folders: teamFolders,
                    spaceType: "team",
                    isAddingFolder: $isAddingTeamFolder
                )
            }

            Spacer()

            // Bottom section
            bottomSection
        }
        .background(Theme.bgSidebar)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        Button {
            appState.isSearchPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                Text("Search")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("⌘K")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.bgCard.opacity(0.5))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.bgInput)
            .cornerRadius(Theme.radiusSM)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.top, 12)
    }

    // MARK: - Nav Item
    private func navItem(title: String, icon: String, item: NavItem) -> some View {
        Button {
            appState.selectedNavItem = item
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(appState.selectedNavItem == item ? Theme.textPrimary : Theme.textSecondary)
                    .frame(width: 20)
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(appState.selectedNavItem == item ? Theme.textPrimary : Theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                appState.selectedNavItem == item ? Theme.bgActive : Color.clear
            )
            .cornerRadius(Theme.radiusSM)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Space Section
    private func spaceSection(
        title: String,
        icon: String,
        folders: [Folder],
        spaceType: String,
        isAddingFolder: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            // Folders
            ForEach(folders) { folder in
                Button {
                    appState.selectedNavItem = .folder(folder.id)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        Text(folder.name)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                    }
                    .padding(.leading, 36)
                    .padding(.trailing, 16)
                    .padding(.vertical, 5)
                    .background(
                        isSelected(folder) ? Theme.bgActive : Color.clear
                    )
                    .cornerRadius(Theme.radiusSM)
                }
                .buttonStyle(.plain)
            }

            // Add folder
            if isAddingFolder.wrappedValue {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    TextField("Folder name", text: $newFolderName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textPrimary)
                        .onSubmit {
                            createFolder(name: newFolderName, spaceType: spaceType)
                            newFolderName = ""
                            isAddingFolder.wrappedValue = false
                        }
                }
                .padding(.leading, 36)
                .padding(.trailing, 16)
                .padding(.vertical, 5)
            }

            Button {
                isAddingFolder.wrappedValue = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                    Text("Add folder")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                    Spacer()
                }
                .padding(.leading, 36)
                .padding(.trailing, 16)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Theme.divider)
                .padding(.horizontal, 16)

            // Action icons
            HStack(spacing: 16) {
                Button {
                    appState.selectedMeeting = nil
                    appState.selectedNavItem = .settings
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)

                Button {
                    appState.selectedMeeting = nil
                    appState.selectedNavItem = .people
                } label: {
                    Image(systemName: "person")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)

                Button {
                    appState.selectedMeeting = nil
                    appState.selectedNavItem = .companies
                } label: {
                    Image(systemName: "building.2")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 16)

            // Plan info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Free Plan")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                Button("Upgrade") { }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.accentGreen)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            // User
            HStack(spacing: 10) {
                Circle()
                    .fill(Theme.accentGreen)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(appState.currentUser?.initials ?? "U")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                Text(appState.currentUser?.displayName ?? "User")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Helpers
    private func isSelected(_ folder: Folder) -> Bool {
        if case .folder(let id) = appState.selectedNavItem {
            return id == folder.id
        }
        return false
    }

    private func createFolder(name: String, spaceType: String) {
        guard !name.isEmpty else { return }
        let folder = Folder(name: name, spaceType: spaceType)
        modelContext.insert(folder)
    }
}
