import NetworkLayer
import SwiftUI

@main
struct ApplaudoChallengeApp: App {
    @State private var catListViewModel: CatListViewModel
    @State private var addCatViewModel: AddCatViewModel
    @State private var savedCatsViewModel: SavedCatsViewModel

    init() {
        let service = CatInformationService()
        let repository = CatBreedRepository(service: service)
        let registeredCatRepository = LocalRegisteredCatRepository()
        _catListViewModel = State(
            initialValue: CatListViewModel(repository: repository)
        )
        _addCatViewModel = State(
            initialValue: AddCatViewModel(repository: registeredCatRepository)
        )
        _savedCatsViewModel = State(
            initialValue: SavedCatsViewModel(repository: registeredCatRepository)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                catListViewModel: catListViewModel,
                addCatViewModel: addCatViewModel,
                savedCatsViewModel: savedCatsViewModel
            )
        }
    }
}
