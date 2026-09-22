protocol CatBreedRepositoryProtocol: Sendable {
    func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreed]
}
