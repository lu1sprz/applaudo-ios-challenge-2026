import NetworkLayer

struct CatBreedRepository: CatBreedRepositoryProtocol, Sendable {
    private let service: any CatInformationServiceProtocol

    init(service: any CatInformationServiceProtocol) {
        self.service = service
    }

    func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreed] {
        try await service.fetchBreeds(page: page, limit: limit).map(CatBreed.init)
    }
}

private extension CatBreed {
    init(response: CatBreedResponse) {
        self.init(
            id: response.id,
            name: response.name,
            description: response.description ?? "No description available.",
            origin: response.origin ?? "Not available",
            temperament: response.temperament ?? "Not available",
            lifeSpan: response.lifeSpan ?? "Not available",
            imageID: response.image?.id ?? response.referenceImageID,
            imageURL: response.image?.url
        )
    }
}
