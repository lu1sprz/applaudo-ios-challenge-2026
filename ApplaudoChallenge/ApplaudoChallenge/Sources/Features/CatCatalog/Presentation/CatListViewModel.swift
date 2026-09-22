import Foundation
import Observation

@MainActor
@Observable
final class CatListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(message: String)
    }

    private(set) var breeds: [CatBreed] = []
    private(set) var state: State = .idle

    private let repository: any CatBreedRepositoryProtocol
    private static let initialPage = 0
    private static let pageSize = 20
    private static let loadErrorMessage = "We couldn't load the cat breeds. Check your connection and try again."

    init(repository: any CatBreedRepositoryProtocol) {
        self.repository = repository
    }

    func loadBreeds() async {
        guard state.canStartRequest else { return }

        state = .loading

        do {
            let breeds = try await repository.fetchBreeds(
                page: Self.initialPage,
                limit: Self.pageSize
            )
            try Task.checkCancellation()

            self.breeds = breeds
            state = breeds.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            state = breeds.isEmpty ? .idle : .loaded
        } catch {
            state = .error(message: Self.loadErrorMessage)
        }
    }

    func retry() async {
        guard case .error = state else { return }
        await loadBreeds()
    }
}

private extension CatListViewModel.State {
    var canStartRequest: Bool {
        switch self {
        case .idle, .error:
            return true
        case .loading, .loaded, .empty:
            return false
        }
    }
}
