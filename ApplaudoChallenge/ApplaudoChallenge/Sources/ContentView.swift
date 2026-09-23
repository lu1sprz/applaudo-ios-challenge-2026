import SwiftUI

public struct ContentView: View {
    let catListViewModel: CatListViewModel
    let addCatViewModel: AddCatViewModel
    let savedCatsViewModel: SavedCatsViewModel

    @State private var selectedTab: AppTab = .catalog

    init(
        catListViewModel: CatListViewModel,
        addCatViewModel: AddCatViewModel,
        savedCatsViewModel: SavedCatsViewModel
    ) {
        self.catListViewModel = catListViewModel
        self.addCatViewModel = addCatViewModel
        self.savedCatsViewModel = savedCatsViewModel
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CatListView(viewModel: catListViewModel)
            }
            .tabItem {
                Label("Cats", systemImage: "cat")
            }
            .tag(AppTab.catalog)

            NavigationStack {
                AddCatStepperView(viewModel: addCatViewModel)
            }
            .tabItem {
                Label("Add Cat", systemImage: "plus.circle")
            }
            .tag(AppTab.registration)

            NavigationStack {
                SavedCatsView(
                    viewModel: savedCatsViewModel,
                    onRegisterCat: { selectedTab = .registration }
                )
            }
            .tabItem {
                Label("Saved", systemImage: "tray.full")
            }
            .tag(AppTab.saved)
        }
        .tint(AppTheme.Colors.primary)
        .task(id: selectedTab) {
            guard selectedTab == .saved else { return }
            await savedCatsViewModel.load()
        }
    }
}

private enum AppTab: Hashable {
    case catalog
    case registration
    case saved
}

#Preview {
    ContentView(
        catListViewModel: CatListViewModel(
            repository: ContentViewPreviewRepository()
        ),
        addCatViewModel: AddCatViewModel(
            repository: ContentViewRegisteredCatPreviewRepository()
        ),
        savedCatsViewModel: SavedCatsViewModel(
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
