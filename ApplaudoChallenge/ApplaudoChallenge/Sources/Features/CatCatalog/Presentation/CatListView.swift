import SwiftUI

struct CatListView: View {
    let viewModel: CatListViewModel

    @State private var catalogRetryTrigger = 0
    @State private var paginationRetryTrigger = 0

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
        .task {
            await viewModel.loadBreeds()
        }
        .task(id: catalogRetryTrigger) {
            guard catalogRetryTrigger > 0 else { return }
            await viewModel.retry()
        }
        .navigationDestination(for: CatCatalogRoute.self) { route in
            destination(for: route)
        }
        .task(id: paginationRetryTrigger) {
            guard paginationRetryTrigger > 0 else { return }
            await viewModel.retryNextPage()
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
                    NavigationLink(value: CatCatalogRoute.detail(breed.id)) {
                        AppCard(
                            title: breed.name,
                            subtitle: breed.description,
                            imageSystemName: "cat.fill",
                            subtitleLineLimit: 3
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("cat-breed-\(breed.id)")
                    .task {
                        await viewModel.loadNextPageIfNeeded(currentBreed: breed)
                    }
                }

                paginationFooter
            }
            .padding(AppTheme.Spacing.md)
        }
        .accessibilityIdentifier("cat-breed-list")
    }

    @ViewBuilder
    private var paginationFooter: some View {
        switch viewModel.paginationState {
        case .loading:
            ProgressView("Loading more breeds…")
                .font(AppTheme.Fonts.caption)
                .tint(AppTheme.Colors.primary)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .padding(.vertical, AppTheme.Spacing.md)
                .accessibilityIdentifier("cat-list-pagination-loading")
        case .error(let message):
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(message)
                    .font(AppTheme.Fonts.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    paginationRetryTrigger += 1
                }
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.primary)
            }
            .padding(.vertical, AppTheme.Spacing.sm)
            .accessibilityIdentifier("cat-list-pagination-error")
        case .idle, .endReached:
            EmptyView()
        }
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
            action: { catalogRetryTrigger += 1 }
        )
        .accessibilityIdentifier("cat-list-error")
    }

    @ViewBuilder
    private func destination(for route: CatCatalogRoute) -> some View {
        switch route {
        case .detail(let breedID):
            if let breed = viewModel.breed(withID: breedID) {
                CatBreedDetailView(breed: breed)
            } else {
                EmptyStateView(
                    systemImage: "cat",
                    title: "Breed Unavailable",
                    message: "This breed is no longer available in the catalog."
                )
            }
        }
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
