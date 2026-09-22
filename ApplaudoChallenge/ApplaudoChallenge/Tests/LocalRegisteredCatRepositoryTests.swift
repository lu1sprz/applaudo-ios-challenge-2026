import Foundation
import Testing
@testable import ApplaudoChallenge

@Suite("Local registered cat repository")
struct LocalRegisteredCatRepositoryTests {
    @Test("It returns an empty collection before the first save")
    func emptyStorage() async throws {
        let fileURL = temporaryFileURL()
        let repository = LocalRegisteredCatRepository(fileURL: fileURL)

        let cats = try await repository.fetchAll()

        #expect(cats.isEmpty)
    }

    @Test("It persists cats across repository instances")
    func persistence() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let cat = RegisteredCat(
            id: UUID(),
            name: "Luna",
            breed: "Abyssinian",
            age: 3,
            description: "Curious and playful.",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let writer = LocalRegisteredCatRepository(fileURL: fileURL)

        try await writer.save(cat)

        let reader = LocalRegisteredCatRepository(fileURL: fileURL)
        let storedCats = try await reader.fetchAll()

        #expect(storedCats == [cat])
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "registered-cats-\(UUID().uuidString).json")
    }
}
