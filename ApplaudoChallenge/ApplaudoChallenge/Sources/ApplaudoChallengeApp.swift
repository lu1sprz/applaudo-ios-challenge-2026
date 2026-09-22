import NetworkLayer
import SwiftUI

@main
struct ApplaudoChallengeApp: App {
    @State private var catListViewModel: CatListViewModel
    @State private var addCatViewModel: AddCatViewModel

    init() {
        let service = CatInformationService()
        let repository = CatBreedRepository(service: service)
        _catListViewModel = State(
            initialValue: CatListViewModel(repository: repository)
        )
        _addCatViewModel = State(
            initialValue: AddCatViewModel(repository: LocalRegisteredCatRepository())
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                catListViewModel: catListViewModel,
                addCatViewModel: addCatViewModel
            )
        }
    }
}
