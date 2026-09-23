import SwiftUI

struct CatBreedDetailView: View {
    let breed: CatBreed

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                breedImage

                detailSection(
                    title: "About",
                    systemImage: "info.circle.fill",
                    content: breed.description
                )

                detailSection(
                    title: "Origin",
                    systemImage: "globe.americas.fill",
                    content: breed.origin
                )

                detailSection(
                    title: "Temperament",
                    systemImage: "heart.fill",
                    content: breed.temperament
                )

                detailSection(
                    title: "Life Span (years)",
                    systemImage: "calendar",
                    content: breed.lifeSpan
                )
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle(breed.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var breedImage: some View {
        Group {
            if let imageURL = breed.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        imagePlaceholder {
                            ProgressView()
                                .tint(AppTheme.Colors.primary)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .accessibilityLabel("\(breed.name) cat")
                    case .failure:
                        unavailableImagePlaceholder
                    @unknown default:
                        unavailableImagePlaceholder
                    }
                }
            } else {
                unavailableImagePlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .clipped()
        .accessibilityIdentifier("cat-breed-detail-image")
    }

    private var unavailableImagePlaceholder: some View {
        imagePlaceholder {
            Image(systemName: "cat.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.Colors.primary)
                .accessibilityLabel("Image unavailable")
        }
    }

    private func imagePlaceholder<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func detailSection(
        title: String,
        systemImage: String,
        content: String
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeader(title: title, systemImage: systemImage)

            Text(content)
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
}

#Preview {
    NavigationStack {
        CatBreedDetailView(
            breed: CatBreed(
                id: "abys",
                name: "Abyssinian",
                description: "An active, intelligent and curious companion.",
                origin: "Egypt",
                temperament: "Active, Curious, Playful",
                lifeSpan: "14-17",
                imageID: "abys-image",
                imageURL: nil
            )
        )
    }
}
