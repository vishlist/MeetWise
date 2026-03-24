import SwiftUI
import SwiftData

struct CompaniesView: View {
    @Query(sort: \Company.name) private var companies: [Company]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Companies")
                    .font(.heading(28))
                    .foregroundStyle(Theme.textHeading)
                    .padding(.top, 40)

                if companies.isEmpty {
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
                    ForEach(companies) { company in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Theme.accentBlue)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "building.2")
                                        .font(.system(size: 14))
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
                            Text("\(company.meetingCount) meetings")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.textMuted)
                        }
                        .padding(12)
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
