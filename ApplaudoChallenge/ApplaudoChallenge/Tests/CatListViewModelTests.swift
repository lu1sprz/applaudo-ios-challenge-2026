import Foundation
import Testing
@testable import ApplaudoChallenge

@MainActor
@Suite("Cat list view model")
struct CatListViewModelTests {
    @Test("It transitions from loading to loaded")
    func loadsBreeds() async throws {
        let repository = ControlledCatBreedRepository()
        let viewModel = CatListViewModel(repository: repository)

        let loadTask = Task { await viewModel.loadBreeds() }
        await repository.waitUntilRequested()

        #expect(viewModel.state == .loading)

        let breeds = [Self.breed(id: "abys")]
        await repository.complete(with: .success(breeds))
        await loadTask.value

        #expect(viewModel.state == .loaded)
        #expect(viewModel.breeds.map(\.id) == breeds.map(\.id))
        #expect(await repository.capturedPagination == Pagination(page: 0, limit: 20))
    }

    @Test("It represents an empty response")
    func emptyResponse() async {
        let repository = CatBreedRepositoryStub(results: [.success([])])
        let viewModel = CatListViewModel(repository: repository)

        await viewModel.loadBreeds()

        #expect(viewModel.state == .empty)
        #expect(viewModel.breeds.isEmpty)
    }

    @Test("It exposes a presentable error")
    func errorResponse() async {
        let repository = CatBreedRepositoryStub(results: [.failure(.unavailable)])
        let viewModel = CatListViewModel(repository: repository)

        await viewModel.loadBreeds()

        #expect(
            viewModel.state == .error(
                message: "We couldn't load the cat breeds. Check your connection and try again."
            )
        )
        #expect(viewModel.breeds.isEmpty)
    }

    @Test("It retries after an error")
    func retry() async {
        let breeds = [Self.breed(id: "aege")]
        let repository = CatBreedRepositoryStub(
            results: [
                .failure(.unavailable),
                .success(breeds),
            ]
        )
        let viewModel = CatListViewModel(repository: repository)

        await viewModel.loadBreeds()
        await viewModel.retry()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.breeds.map(\.id) == breeds.map(\.id))
        #expect(await repository.requestCount == 2)
    }

    @Test("It prevents duplicate concurrent loads")
    func preventsDuplicateLoads() async {
        let repository = ControlledCatBreedRepository()
        let viewModel = CatListViewModel(repository: repository)

        let firstLoad = Task { await viewModel.loadBreeds() }
        await repository.waitUntilRequested()
        await viewModel.loadBreeds()

        #expect(await repository.requestCount == 1)

        await repository.complete(with: .success([]))
        await firstLoad.value
    }

    private static func breed(id: String) -> CatBreed {
        CatBreed(
            id: id,
            name: "Breed \(id)",
            description: "Description",
            origin: "Origin",
            temperament: "Temperament",
            lifeSpan: "10-15",
            imageID: nil,
            imageURL: nil
        )
    }
}

private struct Pagination: Equatable, Sendable {
    let page: Int
    let limit: Int
}

private enum ServiceStubError: Error, LocalizedError, Equatable, Sendable {
    case unavailable

    var errorDescription: String? {
        "The catalog is unavailable."
    }
}

private actor CatBreedRepositoryStub: CatBreedRepositoryProtocol {
    private var results: [Result<[CatBreed], ServiceStubError>]
    private(set) var requestCount = 0

    init(results: [Result<[CatBreed], ServiceStubError>]) {
        self.results = results
    }

    func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
        requestCount += 1
        return try results.removeFirst().get()
    }
}

private actor ControlledCatBreedRepository: CatBreedRepositoryProtocol {
    private var continuation: CheckedContinuation<[CatBreed], any Error>?
    private(set) var requestCount = 0
    private(set) var capturedPagination: Pagination?

    func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
        requestCount += 1
        capturedPagination = Pagination(page: page, limit: limit)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func waitUntilRequested() async {
        while continuation == nil {
            await Task.yield()
        }
    }

    func complete(with result: Result<[CatBreed], ServiceStubError>) {
        let continuation = continuation
        self.continuation = nil
        continuation?.resume(with: result)
    }
}
