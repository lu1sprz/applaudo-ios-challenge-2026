import SwiftUI

public struct ContentView: View {
    let catListViewModel: CatListViewModel
    let addCatViewModel: AddCatViewModel

    init(
        catListViewModel: CatListViewModel,
        addCatViewModel: AddCatViewModel
    ) {
        self.catListViewModel = catListViewModel
        self.addCatViewModel = addCatViewModel
    }

    public var body: some View {
        TabView {
            NavigationStack {
                CatListView(viewModel: catListViewModel)
            }
            .tabItem {
                Label("Cats", systemImage: "cat")
            }

            NavigationStack {
                AddCatStepperView(viewModel: addCatViewModel)
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
        ),
        addCatViewModel: AddCatViewModel(
            repository: ContentViewRegisteredCatPreviewRepository()
        )
    )
}

private struct ContentViewRegisteredCatPreviewRepository: RegisteredCatRepositoryProtocol {
    func save(_ cat: RegisteredCat) async throws {}

    func fetchAll() async throws -> [RegisteredCat] {
        []
    }
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
