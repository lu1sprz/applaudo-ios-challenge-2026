import SwiftUI

struct SavedCatsView: View {
    let viewModel: SavedCatsViewModel
    let onRegisterCat: () -> Void

    @State private var retryRequest = 0

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .loaded:
                catsList
            case .empty:
                emptyView
            case .error(let message):
                errorView(message: message)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .navigationTitle("Saved Cats")
        .task(id: retryRequest) {
            guard retryRequest > 0 else { return }
            await viewModel.load()
        }
    }

    private var loadingView: some View {
        ProgressView("Loading saved cats…")
            .font(AppTheme.Fonts.body)
            .tint(AppTheme.Colors.primary)
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .accessibilityIdentifier("saved-cats-loading")
    }

    private var catsList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(viewModel.cats) { cat in
                    AppCard(
                        title: cat.name,
                        subtitle: subtitle(for: cat),
                        imageSystemName: "pawprint.fill",
                        showChevron: false,
                        subtitleLineLimit: 3
                    )
                    .accessibilityIdentifier("saved-cat-\(cat.id.uuidString)")
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .accessibilityIdentifier("saved-cats-list")
    }

    private var emptyView: some View {
        EmptyStateView(
            systemImage: "tray",
            title: "No Saved Cats",
            message: "You haven't registered any cats yet.",
            buttonTitle: "Register a Cat",
            action: onRegisterCat
        )
        .accessibilityIdentifier("saved-cats-empty")
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            systemImage: "exclamationmark.triangle",
            title: "Unable to Load Saved Cats",
            message: message,
            buttonTitle: "Try Again",
            action: { retryRequest += 1 }
        )
        .accessibilityIdentifier("saved-cats-error")
    }

    private func subtitle(for cat: RegisteredCat) -> String {
        let age = cat.age == 1 ? "1 year old" : "\(cat.age) years old"
        return "\(cat.breed) • \(age)\n\(cat.description)"
    }
}

#Preview("Saved Cats") {
    let viewModel = SavedCatsViewModel(
        repository: SavedCatsPreviewRepository()
    )

    NavigationStack {
        SavedCatsView(
            viewModel: viewModel,
            onRegisterCat: {}
        )
    }
    .task {
        await viewModel.load()
    }
}

private struct SavedCatsPreviewRepository: RegisteredCatRepositoryProtocol {
    func save(_ cat: RegisteredCat) async throws {}

    func fetchAll() async throws -> [RegisteredCat] {
        [
            RegisteredCat(
                id: UUID(),
                name: "Luna",
                breed: "Abyssinian",
                age: 3,
                description: "Curious and playful.",
                createdAt: .now
            ),
        ]
    }
}
