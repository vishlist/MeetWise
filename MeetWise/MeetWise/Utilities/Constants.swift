import Foundation

enum Constants {
    static let appName = "MeetWise"
    static let bundleID = "com.meetwise.app"

    // API Keys — loaded from Secrets.plist (git-ignored) or environment
    static var deepgramAPIKey: String { secret("DEEPGRAM_API_KEY") }
    static var anthropicAPIKey: String { secret("ANTHROPIC_API_KEY") }
    static var openAIAPIKey: String { secret("OPENAI_API_KEY") }

    // Supabase
    static var supabaseURL: String { secret("SUPABASE_URL", fallback: "https://ygwjivwcwoqbhjcogpby.supabase.co") }
    static var supabaseAnonKey: String { secret("SUPABASE_ANON_KEY", fallback: "sb_publishable_zO5IZ9UEwIPNAfPRZXfwWQ_TSf5XBSL") }

    // Stripe (placeholder)
    static let stripePublishableKey = ""
    static let stripeSecretKey = ""

    // Deepgram
    static let deepgramWSURL = "wss://api.deepgram.com/v1/listen"

    // Anthropic
    static let anthropicURL = "https://api.anthropic.com/v1/messages"
    static let anthropicModel = "claude-sonnet-4-20250514"

    // OpenAI
    static let openAIEmbeddingsURL = "https://api.openai.com/v1/embeddings"
    static let openAIEmbeddingsModel = "text-embedding-3-small"

    // MARK: - Secret Loading

    private static var secrets: [String: String] = {
        // Try loading from Secrets.plist in bundle
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
            return dict
        }
        return [:]
    }()

    private static func secret(_ key: String, fallback: String = "") -> String {
        // 1. Environment variable (Xcode scheme)
        if let env = ProcessInfo.processInfo.environment[key], !env.isEmpty { return env }
        // 2. Secrets.plist
        if let val = secrets[key], !val.isEmpty { return val }
        // 3. Fallback
        return fallback
    }
}
