import Foundation

actor LocalRegisteredCatRepository: RegisteredCatRepositoryProtocol {
    private let fileURL: URL

    init(fileURL: URL = LocalRegisteredCatRepository.defaultFileURL()) {
        self.fileURL = fileURL
    }

    func save(_ cat: RegisteredCat) async throws {
        var cats = try readCats()
        cats.append(cat)
        try write(cats)
    }

    func fetchAll() async throws -> [RegisteredCat] {
        try readCats()
    }

    private func readCats() throws -> [RegisteredCat] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([RegisteredCat].self, from: data)
    }

    private func write(_ cats: [RegisteredCat]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(cats)
        try data.write(to: fileURL, options: .atomic)
    }

    private nonisolated static func defaultFileURL() -> URL {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return baseURL
            .appending(path: "ApplaudoChallenge", directoryHint: .isDirectory)
            .appending(path: "registered-cats.json", directoryHint: .notDirectory)
    }
}
