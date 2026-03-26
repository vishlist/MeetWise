import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var sessionManager = MeetingSessionManager()
    @State private var showSearch = false
    @State private var onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var autoRecordCountdown: Int = 0
    @State private var autoRecordTimer: Timer?

    var body: some View {
        @Bindable var state = appState

        Group {
            if onboardingComplete {
                mainAppView
            } else {
                authView
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $state.showPricing) {
            PricingView()
                .environment(appState)
        }
        // Issue 3: Upgrade prompt alert
        .alert("Upgrade to Pro", isPresented: $state.showUpgradePrompt) {
            Button("Upgrade") {
                appState.showPricing = true
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text(appState.upgradePromptMessage)
        }
        .onAppear {
            setupInitialData()
            appState.initializeServices()
            wireMeetingDetection()
        }
        .onChange(of: onboardingComplete) { _, newValue in
            if newValue {
                setupInitialData()
            }
        }
        .onChange(of: appState.isSearchPresented) { _, newValue in
            showSearch = newValue
        }
        .onChange(of: showSearch) { _, newValue in
            appState.isSearchPresented = newValue
        }
        .onChange(of: appState.didSignOut) { _, signedOut in
            if signedOut {
                onboardingComplete = false
                appState.didSignOut = false
            }
        }
    }

    private var mainAppView: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView(sessionManager: sessionManager, toggleSidebar: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        columnVisibility = columnVisibility == .all ? .detailOnly : .all
                    }
                })
                    .navigationSplitViewColumnWidth(min: 200, ideal: Theme.sidebarWidth, max: 280)
            } detail: {
                ZStack(alignment: .topTrailing) {
                    detailView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.bgPrimary)

                    if appState.selectedMeeting == nil {
                        quickNoteHeaderButton
                            .padding(.top, 8)
                            .padding(.trailing, 16)
                    }
                }
            }
            .background(Theme.bgPrimary)

            // Meeting detection banner
            if appState.showMeetingDetectionBanner,
               let detected = appState.meetingDetectionService.detectedMeeting {
                VStack {
                    meetingDetectionBanner(
                        platform: detected.platform.rawValue,
                        windowTitle: detected.windowTitle
                    )
                    .padding(.top, 4)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // CMD+K search overlay
            if showSearch {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture { showSearch = false }

                SearchOverlay(isPresented: $showSearch)
                    .padding(.top, 80)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .onKeyPress(keys: [.init("k")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                showSearch.toggle()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.init("j")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.showChatSidebar.toggle()
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.init("n")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                let meeting = sessionManager.startQuickNote(modelContext: modelContext)
                appState.selectedMeeting = meeting
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Meeting Detection Banner (improved with platform icon + countdown)
    private func meetingDetectionBanner(platform: String, windowTitle: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Platform icon
                Image(systemName: platformIcon(for: platform))
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32, height: 32)
                    .background(Theme.accentSoft)
                    .cornerRadius(Theme.radiusSM)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Meeting detected: \(platform)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(windowTitle)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Auto-record countdown (if active)
                if autoRecordCountdown > 0 {
                    HStack(spacing: 6) {
                        Text("Recording in \(autoRecordCountdown)s")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.accentRed)
                        Button {
                            cancelAutoRecord()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.bgCard)
                                .cornerRadius(Theme.radiusPill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusPill)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        Task {
                            await sessionManager.startRecording(
                                modelContext: modelContext,
                                title: windowTitle,
                                platform: platform
                            )
                            if let meeting = sessionManager.currentMeeting {
                                appState.selectedMeeting = meeting
                            }
                            withAnimation { appState.showMeetingDetectionBanner = false }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle().fill(Theme.accentRed).frame(width: 6, height: 6)
                            Text("Record this meeting")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Theme.accent)
                        .cornerRadius(Theme.radiusPill)
                    }
                    .buttonStyle(.plain)

                    Button {
                        cancelAutoRecord()
                        withAnimation { appState.showMeetingDetectionBanner = false }
                    } label: {
                        Text("Dismiss")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }

    private func platformIcon(for platform: String) -> String {
        switch platform.lowercased() {
        case let p where p.contains("zoom"): return "video.fill"
        case let p where p.contains("meet"): return "video.circle.fill"
        case let p where p.contains("teams"): return "person.3.fill"
        default: return "video.fill"
        }
    }

    private func startAutoRecordCountdown(platform: String, windowTitle: String) {
        autoRecordCountdown = 5
        autoRecordTimer?.invalidate()
        autoRecordTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            Task { @MainActor in
                if self.autoRecordCountdown > 1 {
                    self.autoRecordCountdown -= 1
                } else {
                    self.autoRecordTimer?.invalidate()
                    self.autoRecordTimer = nil
                    self.autoRecordCountdown = 0
                    // Auto-start recording
                    await self.sessionManager.startRecording(
                        modelContext: self.modelContext,
                        title: windowTitle,
                        platform: platform
                    )
                    if let meeting = self.sessionManager.currentMeeting {
                        self.appState.selectedMeeting = meeting
                    }
                    withAnimation { self.appState.showMeetingDetectionBanner = false }
                }
            }
        }
    }

    private func cancelAutoRecord() {
        autoRecordTimer?.invalidate()
        autoRecordTimer = nil
        autoRecordCountdown = 0
    }

    // MARK: - Quick Note Header Button
    private var quickNoteHeaderButton: some View {
        Button {
            let meeting = sessionManager.startQuickNote(modelContext: modelContext)
            appState.selectedMeeting = meeting
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus").font(.system(size: 12, weight: .medium))
                Text("Quick note").font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusSM)
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var detailView: some View {
        if let meeting = appState.selectedMeeting {
            NotepadView(meeting: meeting, sessionManager: sessionManager)
        } else {
            switch appState.selectedNavItem {
            case .home:
                HomeView(sessionManager: sessionManager)
            case .sharedWithMe:
                SharedWithMeView()
            case .chat:
                ChatView()
            case .folder(let id):
                FolderView(folderID: id, sessionManager: sessionManager)
            case .people:
                PeopleView()
            case .companies:
                CompaniesView()
            case .settings:
                SettingsView()
            }
        }
    }

    // MARK: - Setup
    private func setupInitialData() {
        // Only load existing profile — don't create one (auth flow handles creation)
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        if let profile = profiles.first {
            appState.currentUser = profile
            appState.isAuthenticated = true
        }

        // Seed recipes if needed
        RecipeService.seedRecipes(modelContext: modelContext)

        // Validate Supabase session on launch
        if onboardingComplete {
            Task {
                let valid = await SupabaseAuth.shared.validateSession()
                if !valid {
                    // Session expired — force re-login
                    await MainActor.run {
                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
                        UserDefaults.standard.set(false, forKey: "onboardingComplete")
                        onboardingComplete = false
                        appState.isAuthenticated = false
                        appState.currentUser = nil
                    }
                }
            }
        }
    }

    // MARK: - Auth View — Supabase-backed authentication

    // Which screen are we on?
    enum AuthScreen: Hashable { case signIn, signUp, verifyOTP, forgotPassword, forgotPasswordSent }

    @State private var authScreen: AuthScreen = .signUp

    // Shared fields
    @State private var authName = ""
    @State private var authEmail = ""
    @State private var authPassword = ""
    @State private var authError: String?
    @State private var authShowPassword = false
    @State private var authIsLoading = false

    // OTP
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @State private var otpResendCooldown: Int = 0
    @State private var otpResendTimer: Timer?

    // Hover states for buttons
    @State private var authPrimaryHover = false
    @State private var authSecondaryHover = false

    private var authView: some View {
        HStack(spacing: 0) {
            // Left branding panel
            authBrandingPanel
            // Right form panel
            authFormPanel
        }
        .background(Theme.bgPrimary)
    }

    // MARK: - Branding Panel (left)
    private var authBrandingPanel: some View {
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
            Spacer()
            VStack(alignment: .leading, spacing: 14) {
                authFeatureRow(icon: "mic.fill", text: "Auto-record meetings")
                authFeatureRow(icon: "text.quote", text: "Live transcription")
                authFeatureRow(icon: "sparkles", text: "AI-enhanced notes")
                authFeatureRow(icon: "bubble.left.and.text.bubble.right", text: "Ask questions about meetings")
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.bgSidebar)
    }

    private func authFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(Theme.accent)
                .frame(width: 28, height: 28).background(Theme.accentSoft).cornerRadius(6)
            Text(text).font(.system(size: 14, weight: .light)).foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Form Panel (right)
    private var authFormPanel: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Each screen slides in/out
                Group {
                    switch authScreen {
                    case .signUp: signUpView
                    case .verifyOTP: verifyOTPView
                    case .signIn: signInView
                    case .forgotPassword: forgotPasswordView
                    case .forgotPasswordSent: forgotPasswordSentView
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: authScreen.hashValue)

            Spacer()

            Text("By continuing, you agree to our Terms of Service")
                .font(.system(size: 11, weight: .light)).foregroundStyle(Theme.textMuted)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 48)
    }

    // MARK: - Sign Up View (name + email + password in one step)
    private var signUpView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Create your account")
                    .font(.custom("IBMPlexSerif-Bold", size: 28))
                    .foregroundStyle(Theme.textHeading)
                Text("Start capturing your meetings with AI")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(spacing: 14) {
                authInputField(icon: "person", placeholder: "Full name", text: $authName)
                authInputField(icon: "envelope", placeholder: "Email address", text: $authEmail)
                HStack(spacing: 8) {
                    authInputField(icon: "lock", placeholder: "Password", text: $authPassword, isSecure: !authShowPassword)
                    Button { authShowPassword.toggle() } label: {
                        Image(systemName: authShowPassword ? "eye.slash" : "eye")
                            .font(.system(size: 13)).foregroundStyle(Theme.textMuted)
                            .frame(width: 36, height: 36)
                    }.buttonStyle(.plain)
                }

                // Password strength meter
                passwordStrengthMeter

                // Requirements checklist
                passwordRequirementsList
            }
            .frame(maxWidth: 360)

            if let err = authError {
                Text(err).font(.system(size: 13, weight: .light)).foregroundStyle(Theme.accentRed)
                    .frame(maxWidth: 360)
            }

            authPrimaryButton(title: "Create Account", disabled: !allPasswordRequirementsMet || authIsLoading, loading: authIsLoading) {
                performSignUp()
            }

            HStack(spacing: 4) {
                Text("Already have an account?")
                    .font(.system(size: 13, weight: .light)).foregroundStyle(Theme.textSecondary)
                Button {
                    withAnimation(.spring(response: 0.3)) { authError = nil; authScreen = .signIn }
                } label: {
                    Text("Sign in")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.accent)
                }.buttonStyle(.plain)
            }
        }
    }

    // MARK: - Verify OTP View (after sign up, Supabase sends real email)
    private var verifyOTPView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Verify your email")
                    .font(.custom("IBMPlexSerif-Bold", size: 28))
                    .foregroundStyle(Theme.textHeading)
                Text("We sent a 6-digit code to \(authEmail)")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
            }

            otpInputView
                .frame(maxWidth: 360)

            if let err = authError {
                Text(err).font(.system(size: 13, weight: .light)).foregroundStyle(Theme.accentRed)
                    .frame(maxWidth: 360)
            }

            authPrimaryButton(title: "Verify", loading: authIsLoading) {
                performVerifyOTP()
            }

            HStack(spacing: 16) {
                Button {
                    if otpResendCooldown == 0 {
                        resendVerificationEmail()
                    }
                } label: {
                    Text(otpResendCooldown > 0 ? "Resend code (\(otpResendCooldown)s)" : "Resend code")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(otpResendCooldown > 0 ? Theme.textMuted : Theme.accent)
                }
                .buttonStyle(.plain)
                .disabled(otpResendCooldown > 0)

                Button {
                    withAnimation(.spring(response: 0.3)) { authError = nil; authScreen = .signUp }
                } label: {
                    Text("Change email")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.accent)
                }.buttonStyle(.plain)
            }
        }
    }

    // MARK: - Sign In View
    private var signInView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Welcome back")
                    .font(.custom("IBMPlexSerif-Bold", size: 28))
                    .foregroundStyle(Theme.textHeading)
                Text("Sign in to continue")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(spacing: 14) {
                authInputField(icon: "envelope", placeholder: "Email address", text: $authEmail)
                HStack(spacing: 8) {
                    authInputField(icon: "lock", placeholder: "Password", text: $authPassword, isSecure: !authShowPassword)
                    Button { authShowPassword.toggle() } label: {
                        Image(systemName: authShowPassword ? "eye.slash" : "eye")
                            .font(.system(size: 13)).foregroundStyle(Theme.textMuted)
                            .frame(width: 36, height: 36)
                    }.buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 360)

            if let err = authError {
                Text(err).font(.system(size: 13, weight: .light)).foregroundStyle(Theme.accentRed)
                    .frame(maxWidth: 360)
            }

            authPrimaryButton(title: "Sign In", loading: authIsLoading) {
                performSignIn()
            }

            VStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        authError = nil
                        authPassword = ""
                        authScreen = .forgotPassword
                    }
                } label: {
                    Text("Forgot password?")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.accent)
                }.buttonStyle(.plain)

                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 13, weight: .light)).foregroundStyle(Theme.textSecondary)
                    Button {
                        withAnimation(.spring(response: 0.3)) { authError = nil; authScreen = .signUp }
                    } label: {
                        Text("Sign up")
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.accent)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Forgot Password View
    private var forgotPasswordView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Reset your password")
                    .font(.custom("IBMPlexSerif-Bold", size: 28))
                    .foregroundStyle(Theme.textHeading)
                Text("Enter the email associated with your account")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
            }

            authInputField(icon: "envelope", placeholder: "Email address", text: $authEmail)
                .frame(maxWidth: 360)

            if let err = authError {
                Text(err).font(.system(size: 13, weight: .light)).foregroundStyle(Theme.accentRed)
                    .frame(maxWidth: 360)
            }

            authPrimaryButton(title: "Send Reset Link", loading: authIsLoading) {
                performForgotPassword()
            }

            Button {
                withAnimation(.spring(response: 0.3)) { authError = nil; authScreen = .signIn }
            } label: {
                Text("Back to sign in")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.accent)
            }.buttonStyle(.plain)
        }
    }

    // MARK: - Forgot Password Sent Confirmation
    private var forgotPasswordSentView: some View {
        VStack(spacing: 24) {
            Image(systemName: "envelope.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accentGreen)

            VStack(spacing: 8) {
                Text("Check your email")
                    .font(.custom("IBMPlexSerif-Bold", size: 28))
                    .foregroundStyle(Theme.textHeading)
                Text("We sent a password reset link to \(authEmail). Follow the link in the email to reset your password.")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }

            authPrimaryButton(title: "Back to Sign In") {
                authError = nil
                authPassword = ""
                withAnimation { authScreen = .signIn }
            }
        }
    }

    // MARK: - Reusable Auth Input Field
    private func authInputField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(Theme.textMuted).frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: text).textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .light)).foregroundStyle(Theme.textPrimary)
            } else {
                TextField(placeholder, text: text).textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .light)).foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(Theme.bgCard).cornerRadius(Theme.radiusSM)
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: - Primary Button (with hover + loading)
    private func authPrimaryButton(title: String, disabled: Bool = false, loading: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if loading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: 360)
            .padding(.vertical, 12)
            .background((disabled || loading) ? Theme.textMuted : Theme.accent)
            .cornerRadius(Theme.radiusMD)
        }
        .buttonStyle(.plain)
        .disabled(disabled || loading)
    }

    // MARK: - OTP Input Component
    private var otpInputView: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { index in
                OTPDigitField(digit: $otpDigits[index], index: index, digits: $otpDigits)
            }
        }
    }

    // MARK: - Password Strength Meter
    private var passwordStrengthMeter: some View {
        let strength = passwordStrength
        return VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.border)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(strength.color)
                        .frame(width: geo.size.width * strength.fraction, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: strength.fraction)
                }
            }
            .frame(height: 6)

            Text(strength.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(strength.color)
                .animation(.easeInOut(duration: 0.2), value: strength.label)
        }
    }

    private struct PasswordStrengthInfo: Equatable {
        let label: String
        let color: Color
        let fraction: CGFloat
    }

    private var passwordStrength: PasswordStrengthInfo {
        let pw = authPassword
        if pw.isEmpty { return PasswordStrengthInfo(label: "", color: Theme.textMuted, fraction: 0) }

        var score = 0
        if pw.count >= 10 { score += 1 }
        if pw.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if pw.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if pw.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if pw.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*")) != nil { score += 1 }

        switch score {
        case 0...1: return PasswordStrengthInfo(label: "Weak", color: Theme.accentRed, fraction: 0.2)
        case 2: return PasswordStrengthInfo(label: "Fair", color: Theme.accentOrange, fraction: 0.4)
        case 3: return PasswordStrengthInfo(label: "Good", color: Theme.accentYellow, fraction: 0.65)
        case 4: return PasswordStrengthInfo(label: "Strong", color: Theme.accentGreen, fraction: 0.85)
        default: return PasswordStrengthInfo(label: "Very Strong", color: Theme.accentGreen, fraction: 1.0)
        }
    }

    // MARK: - Password Requirements Checklist
    private var passwordRequirementsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            passwordReqRow(met: authPassword.count >= 10, text: "At least 10 characters")
            passwordReqRow(met: authPassword.rangeOfCharacter(from: .uppercaseLetters) != nil, text: "Contains uppercase letter")
            passwordReqRow(met: authPassword.rangeOfCharacter(from: .lowercaseLetters) != nil, text: "Contains lowercase letter")
            passwordReqRow(met: authPassword.rangeOfCharacter(from: .decimalDigits) != nil, text: "Contains number")
            passwordReqRow(met: authPassword.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*")) != nil, text: "Contains special character (!@#$%^&*)")
        }
    }

    private func passwordReqRow(met: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 13))
                .foregroundStyle(met ? Theme.accentGreen : Theme.textMuted)
            Text(text)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(met ? Theme.textPrimary : Theme.textMuted)
        }
    }

    private var allPasswordRequirementsMet: Bool {
        let pw = authPassword
        return pw.count >= 10
            && pw.rangeOfCharacter(from: .uppercaseLetters) != nil
            && pw.rangeOfCharacter(from: .lowercaseLetters) != nil
            && pw.rangeOfCharacter(from: .decimalDigits) != nil
            && pw.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*")) != nil
    }

    // MARK: - Supabase Auth Handlers

    private func performSignUp() {
        authError = nil
        guard !authName.trimmingCharacters(in: .whitespaces).isEmpty else { authError = "Please enter your name"; return }
        guard !authEmail.trimmingCharacters(in: .whitespaces).isEmpty else { authError = "Please enter your email"; return }
        guard authEmail.contains("@") && authEmail.contains(".") else { authError = "Please enter a valid email"; return }
        guard allPasswordRequirementsMet else { authError = "Please meet all password requirements"; return }

        authIsLoading = true
        let email = authEmail.lowercased().trimmingCharacters(in: .whitespaces)
        let password = authPassword

        Task {
            do {
                _ = try await SupabaseAuth.shared.signUp(email: email, password: password)
                // Supabase sends a verification email with OTP code
                await MainActor.run {
                    authIsLoading = false
                    otpDigits = Array(repeating: "", count: 6)
                    startResendCooldown()
                    withAnimation { authScreen = .verifyOTP }
                }
            } catch {
                await MainActor.run {
                    authIsLoading = false
                    authError = error.localizedDescription
                }
            }
        }
    }

    private func performVerifyOTP() {
        authError = nil
        let entered = otpDigits.joined()
        guard entered.count == 6 else { authError = "Please enter the full 6-digit code"; return }

        authIsLoading = true
        let email = authEmail.lowercased().trimmingCharacters(in: .whitespaces)

        Task {
            do {
                let response = try await SupabaseAuth.shared.verifyOTP(email: email, token: entered, type: "signup")
                await MainActor.run {
                    authIsLoading = false
                    otpResendTimer?.invalidate()
                    otpResendTimer = nil

                    // Create local profile in SwiftData
                    let trimmedName = authName.trimmingCharacters(in: .whitespaces)
                    let normalizedEmail = email

                    let profile = UserProfile()
                    profile.fullName = trimmedName
                    profile.email = normalizedEmail
                    profile.isEmailVerified = true
                    if let userId = response.user?.id {
                        profile.supabaseAccessToken = userId
                    }
                    modelContext.insert(profile)

                    UserDefaults.standard.set(normalizedEmail, forKey: "userEmail")
                    UserDefaults.standard.set(true, forKey: "onboardingComplete")
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")

                    try? modelContext.save()
                    RecipeService.seedRecipes(modelContext: modelContext)
                    onboardingComplete = true
                }
            } catch {
                await MainActor.run {
                    authIsLoading = false
                    authError = error.localizedDescription
                }
            }
        }
    }

    private func performSignIn() {
        authError = nil
        guard !authEmail.trimmingCharacters(in: .whitespaces).isEmpty else { authError = "Please enter your email"; return }
        guard !authPassword.isEmpty else { authError = "Please enter your password"; return }

        authIsLoading = true
        let email = authEmail.lowercased().trimmingCharacters(in: .whitespaces)
        let password = authPassword

        Task {
            do {
                let response = try await SupabaseAuth.shared.signIn(email: email, password: password)
                await MainActor.run {
                    authIsLoading = false

                    // Load or create local profile
                    let descriptor = FetchDescriptor<UserProfile>()
                    let profiles = (try? modelContext.fetch(descriptor)) ?? []
                    let profile = profiles.first(where: { $0.email == email }) ?? {
                        let p = UserProfile()
                        p.email = email
                        p.fullName = response.user?.email ?? email
                        modelContext.insert(p)
                        return p
                    }()

                    profile.isEmailVerified = response.user?.isEmailVerified ?? false
                    if let userId = response.user?.id {
                        profile.supabaseAccessToken = userId
                    }
                    try? modelContext.save()

                    UserDefaults.standard.set(email, forKey: "userEmail")
                    UserDefaults.standard.set(true, forKey: "onboardingComplete")
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")

                    RecipeService.seedRecipes(modelContext: modelContext)
                    onboardingComplete = true
                }
            } catch {
                await MainActor.run {
                    authIsLoading = false
                    authError = error.localizedDescription
                }
            }
        }
    }

    private func performForgotPassword() {
        authError = nil
        guard !authEmail.trimmingCharacters(in: .whitespaces).isEmpty else { authError = "Please enter your email"; return }
        guard authEmail.contains("@") && authEmail.contains(".") else { authError = "Please enter a valid email"; return }

        authIsLoading = true
        let email = authEmail.lowercased().trimmingCharacters(in: .whitespaces)

        Task {
            do {
                try await SupabaseAuth.shared.sendPasswordReset(email: email)
                await MainActor.run {
                    authIsLoading = false
                    withAnimation { authScreen = .forgotPasswordSent }
                }
            } catch {
                await MainActor.run {
                    authIsLoading = false
                    authError = error.localizedDescription
                }
            }
        }
    }

    private func resendVerificationEmail() {
        // Re-call signUp to trigger another verification email
        let email = authEmail.lowercased().trimmingCharacters(in: .whitespaces)
        let password = authPassword

        Task {
            do {
                _ = try await SupabaseAuth.shared.signUp(email: email, password: password)
                await MainActor.run {
                    startResendCooldown()
                }
            } catch {
                await MainActor.run {
                    authError = error.localizedDescription
                }
            }
        }
    }

    private func startResendCooldown() {
        otpResendCooldown = 60
        otpResendTimer?.invalidate()
        otpResendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if otpResendCooldown > 1 {
                    otpResendCooldown -= 1
                } else {
                    otpResendCooldown = 0
                    otpResendTimer?.invalidate()
                    otpResendTimer = nil
                }
            }
        }
    }

    private func wireMeetingDetection() {
        // Wire up meeting detection to auto-create meetings
        appState.meetingDetectionService.onMeetingStarted = { [self] detected in
            appState.detectedMeetingPlatform = detected.platform.rawValue
            appState.detectedMeetingTitle = detected.windowTitle
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appState.showMeetingDetectionBanner = true
            }

            // Auto-record with 5-second countdown if user preference is on
            if appState.currentUser?.autoRecord == true {
                startAutoRecordCountdown(
                    platform: detected.platform.rawValue,
                    windowTitle: detected.windowTitle
                )
            }
        }

        appState.meetingDetectionService.onMeetingEnded = { [self] in
            cancelAutoRecord()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appState.showMeetingDetectionBanner = false
            }
            appState.detectedMeetingPlatform = nil
            appState.detectedMeetingTitle = nil
        }
    }
}

// MARK: - OTP Digit Field (individual box with auto-advance, paste support)
struct OTPDigitField: View {
    @Binding var digit: String
    let index: Int
    @Binding var digits: [String]
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("", text: $digit)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(.system(size: 22, weight: .medium, design: .monospaced))
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
            .frame(width: 48, height: 56)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusSM)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSM)
                    .stroke(isFocused ? Theme.accent : Theme.border, lineWidth: isFocused ? 2 : 1)
            )
            .onAppear {
                if index == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isFocused = true
                    }
                }
            }
            .onChange(of: digit) { oldValue, newValue in
                // Handle paste of full code
                let cleaned = newValue.filter { $0.isNumber }
                if cleaned.count >= 6 {
                    let chars = Array(cleaned.prefix(6))
                    for i in 0..<6 {
                        digits[i] = String(chars[i])
                    }
                    isFocused = false
                    return
                }

                // Only keep last digit typed
                if cleaned.count > 1 {
                    digit = String(cleaned.suffix(1))
                } else if cleaned.isEmpty && !newValue.isEmpty {
                    digit = ""
                    return
                } else {
                    digit = cleaned
                }

                // Auto-advance to next field
                if !digit.isEmpty && index < 5 {
                    // We need to move focus forward. We use a small delay for SwiftUI to process.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isFocused = false
                        // Post notification for next field to pick up
                        NotificationCenter.default.post(name: .otpFocusNext, object: nil, userInfo: ["index": index + 1])
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .otpFocusNext)) { notification in
                if let targetIndex = notification.userInfo?["index"] as? Int, targetIndex == index {
                    isFocused = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .otpFocusPrev)) { notification in
                if let targetIndex = notification.userInfo?["index"] as? Int, targetIndex == index {
                    isFocused = true
                }
            }
            .onKeyPress(.delete) {
                if digit.isEmpty && index > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        NotificationCenter.default.post(name: .otpFocusPrev, object: nil, userInfo: ["index": index - 1])
                    }
                }
                return .ignored
            }
    }
}

extension Notification.Name {
    static let otpFocusNext = Notification.Name("otpFocusNext")
    static let otpFocusPrev = Notification.Name("otpFocusPrev")
}
