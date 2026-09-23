public protocol CatInformationServiceProtocol: Sendable {
    func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreedResponse]
}

public struct CatInformationService: CatInformationServiceProtocol, Sendable {
    private let requester: any NetworkingRequesterType

    public init() {
        requester = NetworkingRequester(provider: .networkingProvider())
    }

    init(requester: any NetworkingRequesterType) {
        self.requester = requester
    }

    public func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreedResponse] {
        try await requester.execute(
            request: CatInformationTarget.getBreeds(page: page, limit: limit)
        )
    }
}
