import SwiftUI
import SwiftData

struct CompaniesView: View {
    @Query(sort: \Company.name) private var companies: [Company]
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedCompany: Company?

    private var filteredCompanies: [Company] {
        if searchText.isEmpty { return companies }
        return companies.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Companies")
                    .font(.heading(28))
                    .foregroundStyle(Theme.textHeading)
                    .padding(.top, 40)

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textMuted)
                    TextField("Search companies...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                }
                .padding(10)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)

                if filteredCompanies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "building.2")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.textMuted)
                        Text("No companies yet")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                        Text("Companies from your meetings will appear here")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(filteredCompanies) { company in
                        VStack(alignment: .leading, spacing: 0) {
                            Button {
                                withAnimation { selectedCompany = selectedCompany?.id == company.id ? nil : company }
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Theme.accentBlue)
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Text(String(company.name.prefix(2)).uppercased())
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(company.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Theme.textPrimary)
                                        if let domain = company.domain {
                                            Text(domain)
                                                .font(.system(size: 12))
                                                .foregroundStyle(Theme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    if let contacts = company.contacts {
                                        Text("\(contacts.count) people")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Theme.textMuted)
                                    }

                                    Text("\(company.meetingCount) meetings")
                                        .font(.system(size: 12))
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
                                        ForEach(contacts) { contact in
                                            HStack(spacing: 8) {
                                                Circle().fill(Theme.accentGreen).frame(width: 20, height: 20)
                                                    .overlay(Text(contact.initials).font(.system(size: 8)).foregroundStyle(.white))
                                                Text(contact.name)
                                                    .font(.system(size: 13))
                                                    .foregroundStyle(Theme.textPrimary)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .padding(.bottom, 8)
                                .background(Theme.bgCard.opacity(0.3))
                            }
                        }
                        .background(Theme.bgCard.opacity(0.3))
                        .cornerRadius(Theme.radiusMD)
                    }
                }
            }
            .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }
}
