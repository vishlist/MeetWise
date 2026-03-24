import Foundation

enum Constants {
    static let appName = "MeetWise"
    static let bundleID = "com.meetwise.app"

    // API Keys — loaded from environment or UserDefaults
    static var deepgramAPIKey: String {
        ProcessInfo.processInfo.environment["DEEPGRAM_API_KEY"] ?? UserDefaults.standard.string(forKey: "deepgramAPIKey") ?? ""
    }

    static var anthropicAPIKey: String {
        ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? ""
    }

    static var openAIAPIKey: String {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? UserDefaults.standard.string(forKey: "openAIAPIKey") ?? ""
    }

    // Supabase
    static var supabaseURL: String {
        ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? UserDefaults.standard.string(forKey: "supabaseURL") ?? ""
    }

    static var supabaseAnonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? UserDefaults.standard.string(forKey: "supabaseAnonKey") ?? ""
    }

    // Deepgram
    static let deepgramWSURL = "wss://api.deepgram.com/v1/listen"

    // Anthropic
    static let anthropicURL = "https://api.anthropic.com/v1/messages"
    static let anthropicModel = "claude-sonnet-4-20250514"

    // OpenAI
    static let openAIEmbeddingsURL = "https://api.openai.com/v1/embeddings"
    static let openAIEmbeddingsModel = "text-embedding-3-small"
}
