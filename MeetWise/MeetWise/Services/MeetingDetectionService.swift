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
        // Check immediately
        checkForMeetingWindows()
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func checkForMeetingWindows() {
        let runningApps = NSWorkspace.shared.runningApplications

        // Check for meeting apps/windows
        var foundMeeting: DetectedMeeting?

        for app in runningApps {
            guard app.isActive || app.activationPolicy == .regular else { continue }
            let bundleID = app.bundleIdentifier ?? ""
            let name = app.localizedName ?? ""

            // Google Meet (runs in browser)
            if isBrowser(bundleID) {
                if let meetTitle = findMeetingWindowTitle(for: app, pattern: "Meet -") {
                    foundMeeting = DetectedMeeting(
                        platform: .googleMeet,
                        windowTitle: meetTitle,
                        detectedAt: Date()
                    )
                    break
                }
            }

            // Zoom
            if bundleID.contains("zoom") && name.contains("Zoom") {
                if let zoomTitle = findMeetingWindowTitle(for: app, pattern: "Zoom Meeting") ??
                   findMeetingWindowTitle(for: app, pattern: "meeting") {
                    foundMeeting = DetectedMeeting(
                        platform: .zoom,
                        windowTitle: zoomTitle,
                        detectedAt: Date()
                    )
                    break
                }
            }

            // Microsoft Teams
            if bundleID.contains("teams") || bundleID.contains("Teams") {
                if let teamsTitle = findMeetingWindowTitle(for: app, pattern: "Meeting") ??
                   findMeetingWindowTitle(for: app, pattern: "Call") {
                    foundMeeting = DetectedMeeting(
                        platform: .teams,
                        windowTitle: teamsTitle,
                        detectedAt: Date()
                    )
                    break
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

            if title.localizedCaseInsensitiveContains(pattern) {
                return title
            }
        }
        return nil
    }
}
