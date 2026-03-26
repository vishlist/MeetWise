import SwiftUI
import AppKit

// MARK: - AI Text Action
enum AITextAction: String, CaseIterable, Identifiable {
    case summarize = "Summarize"
    case shorten = "Shorten"
    case longer = "Make longer"
    case grammar = "Fix grammar"
    case translate = "Translate"
    case professional = "Make professional"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .summarize: return "text.justify.leading"
        case .shorten: return "arrow.down.right.and.arrow.up.left"
        case .longer: return "arrow.up.left.and.arrow.down.right"
        case .grammar: return "checkmark.circle"
        case .translate: return "globe"
        case .professional: return "briefcase"
        }
    }

    var prompt: String {
        switch self {
        case .summarize:
            return "Summarize the following text concisely, keeping the key points. Return only the summarized text, no preamble."
        case .shorten:
            return "Shorten the following text while preserving the meaning. Make it more concise. Return only the shortened text, no preamble."
        case .longer:
            return "Expand the following text with more detail and explanation. Keep the same tone. Return only the expanded text, no preamble."
        case .grammar:
            return "Fix any grammar, spelling, and punctuation errors in the following text. Keep the same meaning and tone. Return only the corrected text, no preamble."
        case .translate:
            return "Translate the following text to English. If it is already in English, translate it to Spanish. Return only the translated text, no preamble."
        case .professional:
            return "Rewrite the following text in a professional, polished tone suitable for business communication. Return only the rewritten text, no preamble."
        }
    }
}

// MARK: - AI Text Editor (NSTextView wrapper with floating toolbar)
struct AITextEditor: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = "Start taking notes..."
    var onSelectionChange: ((String, NSRange) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = AITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 4, height: 8)

        // Set font and text color
        textView.font = NSFont.systemFont(ofSize: 15, weight: .light)
        textView.textColor = NSColor(Theme.textPrimary)
        textView.insertionPointColor = NSColor(Theme.textPrimary)

        // Configure text container
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        // Set initial text
        textView.string = text

        scrollView.documentView = textView
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AITextEditor
        weak var textView: NSTextView?

        init(_ parent: AITextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let selectedRange = textView.selectedRange()
            if selectedRange.length > 0 {
                let selectedText = (textView.string as NSString).substring(with: selectedRange)
                parent.onSelectionChange?(selectedText, selectedRange)
            } else {
                parent.onSelectionChange?("", selectedRange)
            }
        }
    }
}

// Custom NSTextView subclass for placeholder support
class AITextView: NSTextView {
    var placeholderString: String = "Start taking notes..."

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if string.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 15, weight: .light),
                .foregroundColor: NSColor(Theme.textMuted)
            ]
            let placeholder = NSAttributedString(string: placeholderString, attributes: attrs)
            placeholder.draw(at: NSPoint(
                x: textContainerInset.width + 5,
                y: textContainerInset.height
            ))
        }
    }

    override var needsDisplay: Bool {
        didSet {
            // Redraw when text changes to show/hide placeholder
        }
    }
}

// MARK: - Floating AI Toolbar
struct AIFloatingToolbar: View {
    let selectedText: String
    let onAction: (AITextAction) -> Void
    let onDismiss: () -> Void
    var isProcessing: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AITextAction.allCases) { action in
                Button {
                    onAction(action)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: action.icon)
                            .font(.system(size: 10))
                        Text(action.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Theme.bgHover)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
            }

            if isProcessing {
                ProgressView()
                    .controlSize(.small)
                    .padding(.horizontal, 6)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusSM)
                .fill(Theme.bgCard)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - AI Text Editor with Toolbar (Composite View)
struct AITextEditorWithToolbar: View {
    @Binding var text: String
    var placeholder: String = "Start taking notes..."

    @State private var selectedText: String = ""
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @State private var showToolbar: Bool = false
    @State private var isProcessing: Bool = false
    @State private var processingAction: AITextAction?

    var body: some View {
        ZStack(alignment: .top) {
            AITextEditor(
                text: $text,
                placeholder: placeholder
            ) { selected, range in
                selectedText = selected
                selectedRange = range
                showToolbar = !selected.isEmpty
            }
            .frame(minHeight: 400)

            if showToolbar && !selectedText.isEmpty {
                AIFloatingToolbar(
                    selectedText: selectedText,
                    onAction: { action in
                        Task {
                            await performAIAction(action)
                        }
                    },
                    onDismiss: {
                        showToolbar = false
                    },
                    isProcessing: isProcessing
                )
                .padding(.horizontal, 4)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeOut(duration: 0.15), value: showToolbar)
            }
        }
    }

    private func performAIAction(_ action: AITextAction) async {
        guard !selectedText.isEmpty else { return }
        isProcessing = true
        processingAction = action

        defer {
            isProcessing = false
            processingAction = nil
        }

        let result = await callClaudeForTextAction(action: action, text: selectedText)

        // Replace the selected text with the result
        if !result.isEmpty, selectedRange.location != NSNotFound {
            let nsString = text as NSString
            // Verify the range is still valid
            if selectedRange.location + selectedRange.length <= nsString.length {
                let before = nsString.substring(to: selectedRange.location)
                let after = nsString.substring(from: selectedRange.location + selectedRange.length)
                text = before + result + after
                showToolbar = false
                selectedText = ""
            }
        }
    }

    private func callClaudeForTextAction(action: AITextAction, text: String) async -> String {
        guard !Constants.anthropicAPIKey.isEmpty else {
            return text // Return original if no API key
        }

        do {
            let url = URL(string: Constants.anthropicURL)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(Constants.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

            let body: [String: Any] = [
                "model": Constants.anthropicModel,
                "max_tokens": 2048,
                "system": action.prompt,
                "messages": [["role": "user", "content": text]]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await URLSession.shared.data(for: request)

            // Parse Claude response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let firstBlock = content.first,
               let resultText = firstBlock["text"] as? String {
                return resultText
            }

            return text // Return original on parse failure
        } catch {
            print("[AITextEditor] API call failed: \(error)")
            return text // Return original on error
        }
    }
}
