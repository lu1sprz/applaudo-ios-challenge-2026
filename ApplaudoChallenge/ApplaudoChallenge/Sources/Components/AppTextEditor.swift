import SwiftUI

struct AppTextEditor: View {
    let label: String
    var placeholder = ""
    @Binding var text: String
    var errorMessage: String?

    private var hasError: Bool {
        errorMessage != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(AppTheme.Fonts.body)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(AppTheme.Fonts.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
            }
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(hasError ? AppTheme.Colors.error : AppTheme.Colors.border)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle")
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.error)
            }
        }
    }
}

#Preview {
    AppTextEditor(
        label: "Description",
        placeholder: "Tell us about your cat",
        text: .constant("")
    )
    .padding(AppTheme.Spacing.md)
}
