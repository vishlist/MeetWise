import SwiftUI
import SwiftData
import CoreText

@main
struct MeetWiseApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Meeting.self,
            MeetingParticipant.self,
            Contact.self,
            Company.self,
            Folder.self,
            TranscriptChunk.self,
            ChatConversation.self,
            ChatMessage.self,
            Recipe.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        registerCustomFonts()
    }

    var body: some Scene {
        // Main window
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1100, height: 750)

        // Menu bar icon
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image(systemName: appState.isRecording ? "waveform.circle.fill" : "waveform.circle")
                .symbolRenderingMode(.hierarchical)
        }
    }

    /// Register bundled fonts at app launch
    private func registerCustomFonts() {
        let fontNames = [
            "IBMPlexSerif-Regular",
            "IBMPlexSerif-Bold",
            "IBMPlexSerif-Light",
            "IBMPlexSerif-Italic"
        ]

        for fontName in fontNames {
            if let url = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                print("[Fonts] Registered: \(fontName)")
            } else {
                print("[Fonts] WARNING: Could not find \(fontName).ttf in bundle")
            }
        }
    }
}
