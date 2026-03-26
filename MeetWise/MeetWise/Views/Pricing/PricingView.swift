import SwiftUI

struct PricingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var isAnnual = false
    @State private var hoveredPlan: String?

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textMuted)
                        .padding(8)
                        .background(Theme.bgCard)
                        .cornerRadius(Theme.radiusSM)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
                .hoverScale(1.1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Choose your plan")
                            .font(.heading(28))
                            .foregroundStyle(Theme.textHeading)

                        Text("Start free, upgrade when you need more")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    // Monthly / Annual toggle
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isAnnual = false }
                        } label: {
                            Text("Monthly")
                                .font(.system(size: 13, weight: isAnnual ? .light : .medium))
                                .foregroundStyle(isAnnual ? Theme.textSecondary : Theme.textPrimary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.radiusSM)
                                        .fill(isAnnual ? .clear : Theme.bgCard)
                                        .shadow(color: isAnnual ? .clear : Color.black.opacity(0.04), radius: 4, y: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isAnnual = true }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Annual")
                                    .font(.system(size: 13, weight: isAnnual ? .medium : .light))
                                    .foregroundStyle(isAnnual ? Theme.textPrimary : Theme.textSecondary)
                                Text("20% off")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.accentSoft)
                                    .cornerRadius(4)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.radiusSM)
                                    .fill(isAnnual ? Theme.bgCard : .clear)
                                    .shadow(color: isAnnual ? Color.black.opacity(0.04) : .clear, radius: 4, y: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                    .background(Theme.bgHover)
                    .cornerRadius(Theme.radiusMD)

                    // Plans
                    HStack(alignment: .top, spacing: 16) {
                        freePlanCard
                        proPlanCard
                        teamPlanCard
                    }
                    .padding(.horizontal, 8)

                    // FAQ
                    faqSection
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .frame(width: 780, height: 700)
        .background(Theme.bgPrimary)
    }

    // MARK: - Free Plan
    private var freePlanCard: some View {
        let currentPlan = appState.currentUser?.plan ?? "free"
        let isCurrent = currentPlan == "free"

        return planCard(
            name: "Free",
            price: "$0",
            period: "/month",
            features: [
                "5 meetings/month",
                "Basic transcription",
                "1 space",
                "Standard audio quality"
            ],
            isRecommended: false,
            isCurrent: isCurrent,
            buttonLabel: isCurrent ? "Current Plan" : "Downgrade",
            buttonAction: { },
            isDisabled: isCurrent
        )
    }

    // MARK: - Pro Plan
    private var proPlanCard: some View {
        let currentPlan = appState.currentUser?.plan ?? "free"
        let isCurrent = currentPlan == "pro"
        let price = isAnnual ? "$16" : "$20"

        return planCard(
            name: "Pro",
            price: price,
            period: "/month",
            features: [
                "Unlimited meetings",
                "AI-enhanced notes",
                "All 12 recipes",
                "Priority transcription",
                "Unlimited spaces",
                "High quality audio"
            ],
            isRecommended: true,
            isCurrent: isCurrent,
            buttonLabel: isCurrent ? "Current Plan" : "Upgrade to Pro",
            buttonAction: {
                StripeService.openCheckout(plan: "pro")
            },
            isDisabled: isCurrent
        )
    }

    // MARK: - Team Plan
    private var teamPlanCard: some View {
        let currentPlan = appState.currentUser?.plan ?? "free"
        let isCurrent = currentPlan == "team"
        let price = isAnnual ? "$12" : "$15"

        return planCard(
            name: "Team",
            price: price,
            period: "/user/month",
            features: [
                "Everything in Pro",
                "Shared spaces",
                "Team notes & collaboration",
                "Admin dashboard",
                "Priority support"
            ],
            isRecommended: false,
            isCurrent: isCurrent,
            buttonLabel: isCurrent ? "Current Plan" : "Contact Sales",
            buttonAction: {
                StripeService.openCheckout(plan: "team")
            },
            isDisabled: isCurrent
        )
    }

    // MARK: - Plan Card Builder
    private func planCard(
        name: String,
        price: String,
        period: String,
        features: [String],
        isRecommended: Bool,
        isCurrent: Bool,
        buttonLabel: String,
        buttonAction: @escaping () -> Void,
        isDisabled: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Badge
            HStack {
                Text(name)
                    .font(.custom("IBMPlexSerif-Bold", size: 16))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if isRecommended {
                    Text("Most Popular")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accent)
                        .cornerRadius(Theme.radiusPill)
                }
            }

            // Price (IBM Plex Serif)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(price)
                    .font(.custom("IBMPlexSerif-Bold", size: 32))
                    .foregroundStyle(Theme.textHeading)
                Text(period)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
            }

            // Features (muted green checkmarks)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.accentGreen)
                        Text(feature)
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            Spacer()

            // Button
            Button(action: buttonAction) {
                Text(buttonLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isDisabled ? Theme.textMuted : (isRecommended ? Color.white : Theme.textPrimary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radiusSM)
                            .fill(isDisabled ? Theme.bgHover : (isRecommended ? Theme.accent : .clear))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusSM)
                            .stroke(isDisabled ? Theme.border : (isRecommended ? .clear : Theme.border), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .hoverScale(isDisabled ? 1.0 : 1.03)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .shadow(color: Color.black.opacity(isRecommended ? 0.08 : 0.04), radius: isRecommended ? 12 : 8, x: 0, y: isRecommended ? 4 : 2)
        .onHover { isHover in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hoveredPlan = isHover ? name : nil
            }
        }
    }

    // MARK: - FAQ
    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequently Asked Questions")
                .font(.custom("IBMPlexSerif-Bold", size: 16))
                .foregroundStyle(Theme.textPrimary)

            faqItem(
                question: "Can I cancel anytime?",
                answer: "Yes, you can cancel your subscription at any time. You'll continue to have access until the end of your billing period."
            )

            faqItem(
                question: "What happens to my data if I downgrade?",
                answer: "Your existing meeting notes and transcriptions are always preserved. You may lose access to some Pro features but your data stays safe."
            )

            faqItem(
                question: "Do you offer student or nonprofit discounts?",
                answer: "Yes! Contact us at support@meetwise.app for special pricing for students, educators, and nonprofit organizations."
            )

            faqItem(
                question: "How does the Team plan work?",
                answer: "The Team plan allows shared spaces where your team can collaborate on meeting notes, share transcripts, and manage meetings together."
            )
        }
        .padding(20)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private func faqItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(question)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Text(answer)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)
        }
        .padding(.vertical, 4)
    }
}
