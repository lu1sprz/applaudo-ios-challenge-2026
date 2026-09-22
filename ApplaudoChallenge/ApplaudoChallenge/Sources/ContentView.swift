import SwiftUI

public struct ContentView: View {
    let catListViewModel: CatListViewModel

    init(catListViewModel: CatListViewModel) {
        self.catListViewModel = catListViewModel
    }

    public var body: some View {
        TabView {
            NavigationStack {
                CatListView(viewModel: catListViewModel)
            }
            .tabItem {
                Label("Cats", systemImage: "cat")
            }

            // MARK: - Tab 2: Add Cat
            // TODO: Replace placeholder with your AddCatStepperView
            NavigationStack {
                Text("Add New Cat")
                    .font(AppTheme.Fonts.title)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .navigationTitle("Add Cat")
            }
            .tabItem {
                Label("Add Cat", systemImage: "plus.circle")
            }
        }
        .tint(AppTheme.Colors.primary)
    }
}

#Preview {
    ContentView(
        catListViewModel: CatListViewModel(
            repository: ContentViewPreviewRepository()
        )
    )
}

private struct ContentViewPreviewRepository: CatBreedRepositoryProtocol {
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
        ]
    }
}
