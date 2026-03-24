import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    @State private var deepgramKey = UserDefaults.standard.string(forKey: "deepgramAPIKey") ?? ""
    @State private var anthropicKey = UserDefaults.standard.string(forKey: "anthropicAPIKey") ?? ""
    @State private var openAIKey = UserDefaults.standard.string(forKey: "openAIAPIKey") ?? ""
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.heading(28))
                    .foregroundStyle(Theme.textHeading)
                    .padding(.top, 40)

                // API Keys section — MOST IMPORTANT
                settingsSection("API Keys") {
                    apiKeyField("Deepgram API Key", key: $deepgramKey, placeholder: "48c6137b...")
                    Divider().background(Theme.divider)
                    apiKeyField("Anthropic API Key", key: $anthropicKey, placeholder: "sk-ant-api03-...")
                    Divider().background(Theme.divider)
                    apiKeyField("OpenAI API Key", key: $openAIKey, placeholder: "sk-proj-...")
                }

                // Save button
                HStack {
                    Button {
                        UserDefaults.standard.set(deepgramKey, forKey: "deepgramAPIKey")
                        UserDefaults.standard.set(anthropicKey, forKey: "anthropicAPIKey")
                        UserDefaults.standard.set(openAIKey, forKey: "openAIAPIKey")
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                    } label: {
                        Text("Save API Keys")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Theme.accentGreen)
                            .cornerRadius(Theme.radiusMD)
                    }
                    .buttonStyle(.plain)

                    if saved {
                        Text("✓ Saved!")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.accentGreen)
                    }
                }

                // Profile section
                settingsSection("Profile") {
                    settingsRow("Name", value: appState.currentUser?.displayName ?? "Not set")
                    settingsRow("Email", value: appState.currentUser?.email ?? "Not set")
                }

                // Recording section
                settingsSection("Recording") {
                    settingsToggle("Auto-record meetings", isOn: true)
                    settingsToggle("Transcript notifications", isOn: true)
                }

                // Status
                settingsSection("Status") {
                    settingsRow("Deepgram", value: Constants.deepgramAPIKey.isEmpty ? "❌ Not set" : "✅ Configured")
                    settingsRow("Anthropic", value: Constants.anthropicAPIKey.isEmpty ? "❌ Not set" : "✅ Configured")
                    settingsRow("OpenAI", value: Constants.openAIAPIKey.isEmpty ? "❌ Not set" : "✅ Configured")
                }
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }

    private func apiKeyField(_ label: String, key: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            SecureField(placeholder, text: key)
                .textFieldStyle(.plain)
                .font(.system(size: 13).monospaced())
                .foregroundStyle(Theme.textPrimary)
                .padding(10)
                .background(Theme.bgInput)
                .cornerRadius(Theme.radiusSM)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusSM)
                        .stroke(Theme.border, lineWidth: 1)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .textCase(.uppercase)
            VStack(spacing: 0) {
                content()
            }
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMD)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func settingsToggle(_ label: String, isOn: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Toggle("", isOn: .constant(isOn))
                .toggleStyle(.switch)
                .tint(Theme.accentGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
