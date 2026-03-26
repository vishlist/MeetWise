import Foundation
import AppKit

class StripeService {
    static let publishableKey = "" // User will add later

    static func openCheckout(plan: String) {
        // Placeholder — will open Stripe Checkout URL
        let url = URL(string: "https://meetwise.app/pricing")!
        NSWorkspace.shared.open(url)
    }

    static func getCurrentPlan() -> String {
        UserDefaults.standard.string(forKey: "userPlan") ?? "free"
    }

    static func setPlan(_ plan: String) {
        UserDefaults.standard.set(plan, forKey: "userPlan")
    }
}
