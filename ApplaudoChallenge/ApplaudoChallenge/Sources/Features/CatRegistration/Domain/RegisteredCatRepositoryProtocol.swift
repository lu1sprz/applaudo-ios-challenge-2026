protocol RegisteredCatRepositoryProtocol: Sendable {
    func save(_ cat: RegisteredCat) async throws
    func fetchAll() async throws -> [RegisteredCat]
}
