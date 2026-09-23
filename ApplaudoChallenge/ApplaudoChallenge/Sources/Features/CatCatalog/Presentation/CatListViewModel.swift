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

    enum PaginationState: Equatable {
        case idle
        case loading
        case endReached
        case error(message: String)
    }

    private(set) var breeds: [CatBreed] = []
    private(set) var state: State = .idle
    private(set) var paginationState: PaginationState = .idle

    private let repository: any CatBreedRepositoryProtocol
    private var currentPage = initialPage
    private static let initialPage = 0
    private static let pageSize = 20
    private static let paginationThreshold = 5
    private static let loadErrorMessage = "We couldn't load the cat breeds. Check your connection and try again."
    private static let paginationErrorMessage = "We couldn't load more breeds. Please try again."

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
            currentPage = Self.initialPage
            paginationState = breeds.count < Self.pageSize ? .endReached : .idle
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

    func loadNextPageIfNeeded(currentBreed: CatBreed) async {
        guard state == .loaded,
              paginationState == .idle,
              let index = breeds.firstIndex(where: { $0.id == currentBreed.id }),
              index >= max(breeds.count - Self.paginationThreshold, 0) else {
            return
        }

        await loadNextPage()
    }

    func retryNextPage() async {
        guard case .error = paginationState else { return }
        await loadNextPage()
    }

    func breed(withID id: CatBreed.ID) -> CatBreed? {
        breeds.first { $0.id == id }
    }

    private func loadNextPage() async {
        guard state == .loaded,
              paginationState.canStartRequest else {
            return
        }

        let requestedPage = currentPage + 1
        paginationState = .loading

        do {
            let newBreeds = try await repository.fetchBreeds(
                page: requestedPage,
                limit: Self.pageSize
            )
            try Task.checkCancellation()

            var knownIDs = Set(breeds.map(\.id))
            breeds.append(
                contentsOf: newBreeds.filter { knownIDs.insert($0.id).inserted }
            )
            currentPage = requestedPage
            paginationState = newBreeds.count < Self.pageSize ? .endReached : .idle
        } catch is CancellationError {
            paginationState = .idle
        } catch {
            paginationState = .error(message: Self.paginationErrorMessage)
        }
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

private extension CatListViewModel.PaginationState {
    var canStartRequest: Bool {
        switch self {
        case .idle, .error:
            return true
        case .loading, .endReached:
            return false
        }
    }
}
