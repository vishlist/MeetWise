import SwiftUI
import SwiftData

struct AuthView: View {
    @Binding var isAuthenticated: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var isSignUp = true
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var error: String?
    @State private var isLoading = false
    @State private var showPassword = false

    var body: some View {
        HStack(spacing: 0) {
            // Left: branding panel
            brandingPanel

            // Right: auth form
            formPanel
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(Theme.bgPrimary)
    }

    // MARK: - Branding Panel (left side)
    private var brandingPanel: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)

            Text("MeetWise")
                .font(.custom("IBMPlexSerif-Bold", size: 36))
                .foregroundStyle(Theme.textHeading)

            Text("AI-powered meeting notes\nthat capture what matters")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()

            // Feature highlights
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "mic.fill", text: "Auto-record meetings")
                featureRow(icon: "text.quote", text: "Live transcription")
                featureRow(icon: "sparkles", text: "AI-enhanced notes")
                featureRow(icon: "bubble.left.and.text.bubble.right", text: "Ask questions about any meeting")
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.bgSidebar)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
                .frame(width: 28, height: 28)
                .background(Theme.accentSoft)
                .cornerRadius(6)

            Text(text)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Form Panel (right side)
    private var formPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.custom("IBMPlexSerif-Bold", size: 28))
                        .foregroundStyle(Theme.textHeading)

                    Text(isSignUp ? "Start capturing your meetings with AI" : "Sign in to continue")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Theme.textSecondary)
                }

                // Form fields
                VStack(spacing: 16) {
                    if isSignUp {
                        authField(icon: "person", placeholder: "Full name", text: $fullName)
                    }

                    authField(icon: "envelope", placeholder: "Email address", text: $email)

                    HStack(spacing: 8) {
                        authField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            isSecure: !showPassword
                        )

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textMuted)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                    }

                    if isSignUp {
                        authField(
                            icon: "lock.shield",
                            placeholder: "Confirm password",
                            text: $confirmPassword,
                            isSecure: true
                        )
                    }
                }
                .frame(maxWidth: 360)

                // Error message
                if let error = error {
                    Text(error)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Theme.accentRed)
                        .multilineTextAlignment(.center)
                }

                // Submit button
                Button {
                    isSignUp ? handleSignUp() : handleSignIn()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: 360)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .cornerRadius(Theme.radiusMD)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                // Toggle sign in / sign up
                HStack(spacing: 4) {
                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Theme.textSecondary)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isSignUp.toggle()
                            error = nil
                        }
                    } label: {
                        Text(isSignUp ? "Sign in" : "Sign up")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Footer
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 48)
    }

    // MARK: - Auth Field
    private func authField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textMuted)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textPrimary)
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusSM)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusSM)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    // MARK: - Handlers
    private func handleSignUp() {
        error = nil

        guard !fullName.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter your name"
            return
        }
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter your email"
            return
        }
        guard email.contains("@") && email.contains(".") else {
            error = "Please enter a valid email"
            return
        }
        guard password.count >= 6 else {
            error = "Password must be at least 6 characters"
            return
        }
        guard password == confirmPassword else {
            error = "Passwords don't match"
            return
        }

        isLoading = true

        // Create user profile locally
        let profile = UserProfile(
            fullName: fullName.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces).lowercased()
        )
        modelContext.insert(profile)

        // Store email + password hash in UserDefaults for local auth
        let emailKey = email.trimmingCharacters(in: .whitespaces).lowercased()
        UserDefaults.standard.set(emailKey, forKey: "userEmail")
        UserDefaults.standard.set(password.hashValue, forKey: "userPasswordHash")
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        UserDefaults.standard.set(true, forKey: "isLoggedIn")

        try? modelContext.save()
        RecipeService.seedRecipes(modelContext: modelContext)

        isLoading = false
        isAuthenticated = true
    }

    private func handleSignIn() {
        error = nil

        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            error = "Please enter your email"
            return
        }
        guard !password.isEmpty else {
            error = "Please enter your password"
            return
        }

        isLoading = true

        let storedEmail = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let storedHash = UserDefaults.standard.integer(forKey: "userPasswordHash")
        let inputEmail = email.trimmingCharacters(in: .whitespaces).lowercased()

        if inputEmail == storedEmail && password.hashValue == storedHash {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            UserDefaults.standard.set(true, forKey: "onboardingComplete")
            isLoading = false
            isAuthenticated = true
        } else {
            isLoading = false
            error = "Invalid email or password"
        }
    }
}
