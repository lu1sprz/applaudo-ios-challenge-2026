import Foundation
import Testing
@testable import ApplaudoChallenge

@MainActor
@Suite("Saved cats view model")
struct SavedCatsViewModelTests {
    @Test("It loads cats newest first")
    func loadsCats() async {
        let olderCat = Self.cat(name: "Luna", createdAt: Date(timeIntervalSince1970: 1))
        let newerCat = Self.cat(name: "Milo", createdAt: Date(timeIntervalSince1970: 2))
        let repository = SavedCatsRepositoryStub(
            results: [.success([olderCat, newerCat])]
        )
        let viewModel = SavedCatsViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.cats.map(\.name) == ["Milo", "Luna"])
    }

    @Test("It represents empty storage")
    func emptyStorage() async {
        let repository = SavedCatsRepositoryStub(results: [.success([])])
        let viewModel = SavedCatsViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .empty)
        #expect(viewModel.cats.isEmpty)
    }

    @Test("It exposes an error and can load again")
    func retryAfterFailure() async {
        let cat = Self.cat(name: "Luna", createdAt: .now)
        let repository = SavedCatsRepositoryStub(
            results: [
                .failure(.unavailable),
                .success([cat]),
            ]
        )
        let viewModel = SavedCatsViewModel(repository: repository)

        await viewModel.load()

        #expect(
            viewModel.state == .error(
                message: "We couldn't load your saved cats. Please try again."
            )
        )

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.cats.map(\.id) == [cat.id])
        #expect(await repository.requestCount == 2)
    }

    private static func cat(name: String, createdAt: Date) -> RegisteredCat {
        RegisteredCat(
            id: UUID(),
            name: name,
            breed: "Abyssinian",
            age: 3,
            description: "Curious and playful.",
            createdAt: createdAt
        )
    }
}

private enum SavedCatsRepositoryStubError: Error, Sendable {
    case unavailable
}

private actor SavedCatsRepositoryStub: RegisteredCatRepositoryProtocol {
    private var results: [Result<[RegisteredCat], SavedCatsRepositoryStubError>]
    private(set) var requestCount = 0

    init(results: [Result<[RegisteredCat], SavedCatsRepositoryStubError>]) {
        self.results = results
    }

    func save(_ cat: RegisteredCat) async throws {}

    func fetchAll() async throws -> [RegisteredCat] {
        requestCount += 1
        return try results.removeFirst().get()
    }
}
