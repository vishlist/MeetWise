import SwiftUI
import SwiftData

struct CompaniesView: View {
    @Query(sort: \Company.name) private var companies: [Company]
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCompany: Company?
    @State private var showCreateSheet = false
    @State private var newCompanyName = ""
    @State private var newCompanyDomain = ""

    private var filteredCompanies: [Company] {
        if searchText.isEmpty { return companies }
        return companies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.domain?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Companies")
                        .font(.heading(28))
                        .foregroundStyle(Theme.textHeading)

                    Spacer()

                    Button {
                        showCreateSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11))
                            Text("Add Company")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.pastelLavender)
                        .cornerRadius(Theme.radiusSM)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 40)

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted)
                    TextField("Search companies...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .light))
                }
                .padding(10)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)

                if filteredCompanies.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredCompanies) { company in
                        companyRow(company)
                    }
                }
            }
            .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
        .sheet(isPresented: $showCreateSheet) {
            createCompanySheet
        }
    }

    private func companyRow(_ company: Company) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { selectedCompany = selectedCompany?.id == company.id ? nil : company }
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.pastelLavender)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(company.name.prefix(2)).uppercased())
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.accent)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(company.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                        if let domain = company.domain {
                            Text(domain)
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    Spacer()

                    if let contacts = company.contacts {
                        Text("\(contacts.count) people")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Theme.textMuted)
                    }

                    Text("\(company.meetingCount) meetings")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Theme.textMuted)

                    Image(systemName: selectedCompany?.id == company.id ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded: contacts + meetings
            if selectedCompany?.id == company.id {
                VStack(spacing: 0) {
                    if let contacts = company.contacts, !contacts.isEmpty {
                        Text("People")
                            .font(.custom("Georgia", size: 11))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                        ForEach(contacts) { contact in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Theme.pastelBlue)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Text(contact.initials)
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundStyle(Theme.accent)
                                    )
                                Text(contact.name)
                                    .font(.system(size: 13, weight: .light))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if let email = contact.email {
                                    Text(email)
                                        .font(.system(size: 11, weight: .light))
                                        .foregroundStyle(Theme.textMuted)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                    }

                    // Recent meetings involving this company's contacts
                    let companyContactNames = Set(company.contacts?.map(\.name) ?? [])
                    let companyMeetings = meetings.filter { meeting in
                        meeting.participants?.contains(where: { companyContactNames.contains($0.name) }) ?? false
                    }

                    if !companyMeetings.isEmpty {
                        Text("Recent Meetings")
                            .font(.custom("Georgia", size: 11))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                        ForEach(companyMeetings.prefix(5)) { meeting in
                            Button { appState.selectedMeeting = meeting } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textMuted)
                                    Text(meeting.title)
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(meeting.formattedDate)
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundStyle(Theme.textMuted)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, 8)
                .background(Theme.bgPrimary.opacity(0.5))
            }
        }
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 36))
                .foregroundStyle(Theme.textMuted)
            Text("No companies yet")
                .font(.custom("Georgia", size: 14))
                .foregroundStyle(Theme.textSecondary)
            Text("Companies from your meetings will appear here")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Theme.textMuted)

            Button {
                showCreateSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                    Text("Add Company")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.accent)
                .cornerRadius(Theme.radiusPill)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Create Company Sheet
    private var createCompanySheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Company")
                .font(.custom("Georgia", size: 16))
                .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                TextField("Company name", text: $newCompanyName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .light))
                    .padding(10)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Domain (optional)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                TextField("example.com", text: $newCompanyDomain)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .light))
                    .padding(10)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    showCreateSheet = false
                    newCompanyName = ""
                    newCompanyDomain = ""
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.textSecondary)

                Button("Create") {
                    guard !newCompanyName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let company = Company(name: newCompanyName.trimmingCharacters(in: .whitespaces))
                    if !newCompanyDomain.trimmingCharacters(in: .whitespaces).isEmpty {
                        company.domain = newCompanyDomain.trimmingCharacters(in: .whitespaces)
                    }
                    modelContext.insert(company)
                    try? modelContext.save()
                    showCreateSheet = false
                    newCompanyName = ""
                    newCompanyDomain = ""
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.accent)
                .cornerRadius(Theme.radiusPill)
                .buttonStyle(.plain)
                .disabled(newCompanyName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Theme.bgPrimary)
    }
}
