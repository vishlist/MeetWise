import Foundation

enum Constants {
    static let appName = "MeetWise"
    static let bundleID = "com.meetwise.app"

    // API Keys — hardcoded
    static let deepgramAPIKey = "YOUR_KEY"
    static let anthropicAPIKey = "YOUR_KEY"
    static let openAIAPIKey = "YOUR_KEY"

    // Supabase
    static let supabaseURL = "https://ygwjivwcwoqbhjcogpby.supabase.co"
    static let supabaseAnonKey = "sb_publishable_zO5IZ9UEwIPNAfPRZXfwWQ_TSf5XBSL"

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
}
