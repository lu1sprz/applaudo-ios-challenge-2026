import SwiftUI

struct CatListView: View {
    let viewModel: CatListViewModel

    @State private var loadRequest = 0

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .loaded:
                breedList
            case .empty:
                emptyView
            case .error(let message):
                errorView(message: message)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .navigationTitle("Cat Breeds")
        .task(id: loadRequest) {
            if loadRequest == 0 {
                await viewModel.loadBreeds()
            } else {
                await viewModel.retry()
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Loading breeds…")
            .font(AppTheme.Fonts.body)
            .tint(AppTheme.Colors.primary)
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .accessibilityIdentifier("cat-list-loading")
    }

    private var breedList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(viewModel.breeds) { breed in
                    AppCard(
                        title: breed.name,
                        subtitle: breed.description,
                        imageSystemName: "cat.fill",
                        showChevron: false,
                        subtitleLineLimit: 3
                    )
                    .accessibilityIdentifier("cat-breed-\(breed.id)")
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .accessibilityIdentifier("cat-breed-list")
    }

    private var emptyView: some View {
        EmptyStateView(
            systemImage: "cat",
            title: "No Breeds Found",
            message: "There are no cat breeds available right now."
        )
        .accessibilityIdentifier("cat-list-empty")
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            systemImage: "wifi.exclamationmark",
            title: "Unable to Load Breeds",
            message: message,
            buttonTitle: "Try Again",
            action: { loadRequest += 1 }
        )
        .accessibilityIdentifier("cat-list-error")
    }
}

#Preview {
    NavigationStack {
        CatListView(
            viewModel: CatListViewModel(repository: CatBreedPreviewRepository())
        )
    }
}

private struct CatBreedPreviewRepository: CatBreedRepositoryProtocol {
    func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
        [
            CatBreed(
                id: "abys",
                name: "Abyssinian",
                description: "An active, intelligent and curious companion.",
                origin: "Egypt",
                temperament: "Active, Curious",
                lifeSpan: "14-17",
                imageID: "abys-image",
                imageURL: nil
            ),
            CatBreed(
                id: "aege",
                name: "Aegean",
                description: "A friendly and social natural breed.",
                origin: "Greece",
                temperament: "Affectionate, Social",
                lifeSpan: "9-12",
                imageID: nil,
                imageURL: nil
            ),
        ]
    }
}
