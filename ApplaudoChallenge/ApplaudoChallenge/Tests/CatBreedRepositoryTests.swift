import Foundation
import NetworkLayer
import Testing
@testable import ApplaudoChallenge

@Suite("Cat breed repository")
struct CatBreedRepositoryTests {
    @Test("It maps network responses into domain models")
    func mapsResponse() async throws {
        let imageURL = try #require(
            URL(string: "https://cdn2.thecatapi.com/images/abys.jpg")
        )
        let response = CatBreedResponse(
            id: "abys",
            name: "Abyssinian",
            description: "An active and curious breed.",
            origin: "Egypt",
            temperament: "Active, Curious",
            lifeSpan: "14-17",
            referenceImageID: "abys-image",
            image: CatImageResponse(
                id: "abys-image",
                url: imageURL,
                width: 1200,
                height: 800
            )
        )
        let service = CatInformationServiceStub(result: .success([response]))
        let repository = CatBreedRepository(service: service)

        let breeds = try await repository.fetchBreeds(page: 2, limit: 10)

        let breed = try #require(breeds.first)
        #expect(breeds.count == 1)
        #expect(breed.id == response.id)
        #expect(breed.name == response.name)
        #expect(breed.description == response.description)
        #expect(breed.origin == response.origin)
        #expect(breed.temperament == response.temperament)
        #expect(breed.lifeSpan == response.lifeSpan)
        #expect(breed.imageID == response.image?.id)
        #expect(breed.imageURL == imageURL)
        #expect(await service.capturedPagination == Pagination(page: 2, limit: 10))
    }

    @Test("It maps a missing response image to a nil URL")
    func mapsMissingImage() async throws {
        let response = CatBreedResponse(
            id: "aege",
            name: "Aegean",
            description: "A natural breed.",
            origin: "Greece",
            temperament: "Affectionate",
            lifeSpan: "9-12",
            referenceImageID: "aege-reference",
            image: nil
        )
        let service = CatInformationServiceStub(result: .success([response]))
        let repository = CatBreedRepository(service: service)

        let breeds = try await repository.fetchBreeds(page: 0, limit: 10)

        #expect(breeds.first?.imageID == response.referenceImageID)
        #expect(breeds.first?.imageURL == nil)
    }

    @Test("It propagates service errors")
    func propagatesError() async {
        let service = CatInformationServiceStub(result: .failure(.unavailable))
        let repository = CatBreedRepository(service: service)

        do {
            _ = try await repository.fetchBreeds(page: 0, limit: 10)
            Issue.record("Expected the repository request to fail")
        } catch let error as ServiceStubError {
            #expect(error == .unavailable)
        } catch {
            Issue.record("Expected ServiceStubError, received \(error)")
        }
    }
}

private struct Pagination: Equatable, Sendable {
    let page: Int
    let limit: Int
}

private enum ServiceStubError: Error, Equatable, Sendable {
    case unavailable
}

private actor CatInformationServiceStub: CatInformationServiceProtocol {
    private let result: Result<[CatBreedResponse], ServiceStubError>
    private var pagination: Pagination?

    init(result: Result<[CatBreedResponse], ServiceStubError>) {
        self.result = result
    }

    var capturedPagination: Pagination? {
        pagination
    }

    func fetchBreeds(page: Int, limit: Int) async throws -> [CatBreedResponse] {
        pagination = Pagination(page: page, limit: limit)

        return try result.get()
    }
}
