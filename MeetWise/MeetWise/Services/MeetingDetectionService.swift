import Foundation
import AppKit
import Combine

/// Detects when the user is in a meeting by watching for Google Meet, Zoom, or Teams windows
@MainActor @Observable
final class MeetingDetectionService {
    var detectedMeeting: DetectedMeeting?
    var isMonitoring = false

    struct DetectedMeeting {
        let platform: MeetingPlatform
        let windowTitle: String
        let detectedAt: Date
    }

    enum MeetingPlatform: String {
        case googleMeet = "Google Meet"
        case zoom = "Zoom"
        case teams = "Microsoft Teams"
        case unknown = "Unknown"
    }

    private var timer: Timer?
    private var lastDetectedPlatform: MeetingPlatform?

    // Callbacks
    var onMeetingStarted: ((DetectedMeeting) -> Void)?
    var onMeetingEnded: (() -> Void)?

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Check every 3 seconds for meeting windows
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForMeetingWindows()
            }
        }
        // Ensure timer fires on common run loop modes
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        // Check immediately
        checkForMeetingWindows()
        print("[MeetDetect] Started monitoring for meeting windows")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        print("[MeetDetect] Stopped monitoring")
    }

    private func checkForMeetingWindows() {
        let runningApps = NSWorkspace.shared.runningApplications

        // Also check by bundle ID for native apps (Issue 8: fallback detection)
        let zoomRunning = runningApps.contains { ($0.bundleIdentifier ?? "").contains("us.zoom.xos") }
        let teamsRunning = runningApps.contains { ($0.bundleIdentifier ?? "").contains("com.microsoft.teams") }

        // Check for meeting apps/windows
        var foundMeeting: DetectedMeeting?

        for app in runningApps {
            guard app.activationPolicy == .regular else { continue }
            let bundleID = app.bundleIdentifier ?? ""
            let name = app.localizedName ?? ""

            // Google Meet (runs in browser) — Issue 8: broader patterns
            if isBrowser(bundleID) {
                // Check multiple patterns for Google Meet
                if let meetTitle = findMeetingWindowTitle(for: app, pattern: "Meet -") ??
                   findMeetingWindowTitle(for: app, pattern: "Google Meet") ??
                   findMeetingWindowTitle(for: app, pattern: "meet.google.com") {
                    foundMeeting = DetectedMeeting(
                        platform: .googleMeet,
                        windowTitle: cleanWindowTitle(meetTitle),
                        detectedAt: Date()
                    )
                    print("[MeetDetect] Found Google Meet window: \(meetTitle)")
                    break
                }
            }

            // Zoom — Issue 8: check by bundle ID and broader window patterns
            if bundleID.contains("zoom") || name.contains("Zoom") {
                if let zoomTitle = findMeetingWindowTitle(for: app, pattern: "Zoom Meeting") ??
                   findMeetingWindowTitle(for: app, pattern: "Zoom") ??
                   findMeetingWindowTitle(for: app, pattern: "meeting") {
                    foundMeeting = DetectedMeeting(
                        platform: .zoom,
                        windowTitle: cleanWindowTitle(zoomTitle),
                        detectedAt: Date()
                    )
                    print("[MeetDetect] Found Zoom window: \(zoomTitle)")
                    break
                }
            }

            // Microsoft Teams — Issue 8: broader matching
            if bundleID.contains("teams") || bundleID.contains("Teams") || name.contains("Teams") {
                if let teamsTitle = findMeetingWindowTitle(for: app, pattern: "Meeting") ??
                   findMeetingWindowTitle(for: app, pattern: "Call") ??
                   findMeetingWindowTitle(for: app, pattern: "Microsoft Teams") {
                    foundMeeting = DetectedMeeting(
                        platform: .teams,
                        windowTitle: cleanWindowTitle(teamsTitle),
                        detectedAt: Date()
                    )
                    print("[MeetDetect] Found Teams window: \(teamsTitle)")
                    break
                }
            }
        }

        // Issue 8: Fallback — if native app is running but no window title matched, still detect
        if foundMeeting == nil && zoomRunning {
            // Zoom is running — check if it has any significant window
            if let zoomApp = runningApps.first(where: { ($0.bundleIdentifier ?? "").contains("us.zoom.xos") }) {
                if let anyTitle = findAnyWindowTitle(for: zoomApp) {
                    print("[MeetDetect] Zoom running with window: \(anyTitle)")
                    // Only consider it a meeting if the window isn't just the home screen
                    if !anyTitle.localizedCaseInsensitiveContains("Home") && !anyTitle.isEmpty {
                        foundMeeting = DetectedMeeting(platform: .zoom, windowTitle: anyTitle, detectedAt: Date())
                    }
                }
            }
        }

        if foundMeeting == nil && teamsRunning {
            if let teamsApp = runningApps.first(where: { ($0.bundleIdentifier ?? "").contains("com.microsoft.teams") }) {
                if let anyTitle = findAnyWindowTitle(for: teamsApp) {
                    print("[MeetDetect] Teams running with window: \(anyTitle)")
                    if anyTitle.localizedCaseInsensitiveContains("meeting") || anyTitle.localizedCaseInsensitiveContains("call") {
                        foundMeeting = DetectedMeeting(platform: .teams, windowTitle: anyTitle, detectedAt: Date())
                    }
                }
            }
        }

        // Detect transitions
        if let meeting = foundMeeting, detectedMeeting == nil {
            // Meeting just started
            detectedMeeting = meeting
            lastDetectedPlatform = meeting.platform
            onMeetingStarted?(meeting)
            print("[MeetDetect] Meeting detected: \(meeting.platform.rawValue) - \(meeting.windowTitle)")
        } else if foundMeeting == nil && detectedMeeting != nil {
            // Meeting ended
            detectedMeeting = nil
            lastDetectedPlatform = nil
            onMeetingEnded?()
            print("[MeetDetect] Meeting ended")
        }
    }

    private func cleanWindowTitle(_ title: String) -> String {
        // Remove common browser suffixes
        var cleaned = title
        let suffixes = [" - Google Chrome", " - Safari", " - Firefox", " - Microsoft Edge", " - Brave", " - Opera", " - Vivaldi", " - Arc"]
        for suffix in suffixes {
            if cleaned.hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count))
            }
        }
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    private func isBrowser(_ bundleID: String) -> Bool {
        let browsers = [
            "com.google.Chrome", "com.apple.Safari", "company.thebrowser.Browser",
            "org.mozilla.firefox", "com.microsoft.edgemac", "com.brave.Browser",
            "com.operasoftware.Opera", "com.vivaldi.Vivaldi"
        ]
        return browsers.contains(where: { bundleID.contains($0) })
    }

    private func findMeetingWindowTitle(for app: NSRunningApplication, pattern: String) -> String? {
        // Use CGWindowListCopyWindowInfo to get window titles
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        let pid = app.processIdentifier

        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                  ownerPID == pid,
                  let title = window[kCGWindowName as String] as? String,
                  !title.isEmpty else { continue }

            // Issue 8: Log all detected windows for debugging
            let appName = window[kCGWindowOwnerName as String] as? String ?? "Unknown"
            print("[MeetDetect] Found window: \(title) in \(appName)")

            if title.localizedCaseInsensitiveContains(pattern) {
                return title
            }
        }
        return nil
    }

    /// Issue 8: Find any non-empty window title for a given app
    private func findAnyWindowTitle(for app: NSRunningApplication) -> String? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        let pid = app.processIdentifier

        for window in windowList {
            guard let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                  ownerPID == pid,
                  let title = window[kCGWindowName as String] as? String,
                  !title.isEmpty else { continue }
            return title
        }
        return nil
    }
}
