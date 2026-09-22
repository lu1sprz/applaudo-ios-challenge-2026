import NetworkLayer
import SwiftUI

@main
struct ApplaudoChallengeApp: App {
    @State private var catListViewModel: CatListViewModel

    init() {
        let service = CatInformationService()
        let repository = CatBreedRepository(service: service)
        _catListViewModel = State(
            initialValue: CatListViewModel(repository: repository)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(catListViewModel: catListViewModel)
        }
    }
}
