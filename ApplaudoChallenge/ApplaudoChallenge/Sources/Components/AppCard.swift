import SwiftUI

struct AppCard: View {

    let title: String
    var subtitle: String = ""
    var imageSystemName: String = "photo"
    var showChevron: Bool = true
    var subtitleLineLimit: Int?

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Image
            Image(systemName: imageSystemName)
                .font(.title2)
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 50, height: 50)
                .background(AppTheme.Colors.primary.opacity(0.1))
                .clipShape(Circle())

            // Text Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Fonts.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(subtitleLineLimit)
                }
            }

            Spacer()

            // Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("App Card") {
    VStack(spacing: AppTheme.Spacing.md) {
        AppCard(
            title: "Persian",
            subtitle: "Calm and affectionate breed",
            imageSystemName: "cat"
        )

        AppCard(
            title: "Siamese",
            subtitle: "Vocal and social breed",
            imageSystemName: "cat.fill"
        )

        AppCard(
            title: "No Arrow",
            subtitle: "Card without chevron",
            imageSystemName: "pawprint.fill",
            showChevron: false
        )
    }
    .padding(AppTheme.Spacing.lg)
}
