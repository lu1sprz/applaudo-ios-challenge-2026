import Observation

@MainActor
@Observable
final class SavedCatsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(message: String)
    }

    private(set) var cats: [RegisteredCat] = []
    private(set) var state: State = .idle

    private let repository: any RegisteredCatRepositoryProtocol
    private static let loadErrorMessage = "We couldn't load your saved cats. Please try again."

    init(repository: any RegisteredCatRepositoryProtocol) {
        self.repository = repository
    }

    func load() async {
        guard state != .loading else { return }

        state = .loading

        do {
            let cats = try await repository.fetchAll()
            try Task.checkCancellation()

            self.cats = cats.sorted { $0.createdAt > $1.createdAt }
            state = cats.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            state = cats.isEmpty ? .idle : .loaded
        } catch {
            state = .error(message: Self.loadErrorMessage)
        }
    }
}
