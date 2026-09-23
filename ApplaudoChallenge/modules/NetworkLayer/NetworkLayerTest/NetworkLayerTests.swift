import Foundation
import Moya
import Testing
@testable import NetworkLayer

@Suite("Cat information service")
struct NetworkLayerTests {
    @Test("It decodes a page of breeds and forwards pagination")
    func fetchBreeds() async throws {
        let requester = NetworkingRequesterStub(
            result: .success(Self.breedsFixture)
        )
        let service = CatInformationService(requester: requester)

        let breeds = try await service.fetchBreeds(page: 2, limit: 10)

        #expect(breeds.count == 1)
        #expect(breeds.first?.id == "abys")
        #expect(breeds.first?.name == "Abyssinian")
        #expect(breeds.first?.lifeSpan == "14 - 15")
        #expect(breeds.first?.referenceImageID == "0XYvRd7oD")
        #expect(breeds.first?.image?.url.absoluteString == "https://cdn2.thecatapi.com/images/0XYvRd7oD.jpg")
        #expect(await requester.capturedPagination == Pagination(page: 2, limit: 10))
    }

    @Test("It accepts nullable breed metadata")
    func nullableBreedMetadata() async throws {
        let requester = NetworkingRequesterStub(
            result: .success(Self.nullableBreedFixture)
        )
        let service = CatInformationService(requester: requester)

        let breeds = try await service.fetchBreeds(page: 1, limit: 20)

        let breed = try #require(breeds.first)
        #expect(breed.id == "cara")
        #expect(breed.description == nil)
        #expect(breed.origin == nil)
        #expect(breed.temperament == nil)
        #expect(breed.lifeSpan == nil)
    }

    @Test("It maps malformed JSON to a decoding error")
    func decodingFailure() async {
        let requester = NetworkingRequesterStub(
            result: .success(Data("{}".utf8))
        )
        let service = CatInformationService(requester: requester)

        do {
            _ = try await service.fetchBreeds(page: 0, limit: 10)
            Issue.record("Expected the request to fail decoding")
        } catch NetworkError.decodingFailed {
            // Expected.
        } catch {
            Issue.record("Expected decodingFailed, received \(error)")
        }
    }

    @Test("It maps non-successful HTTP responses to server errors")
    func serverError() async {
        let expectedData = Data("rate limited".utf8)
        let provider = MoyaProvider<MultiTarget>(
            endpointClosure: { target in
                Endpoint(
                    url: URL(target: target).absoluteString,
                    sampleResponseClosure: {
                        .networkResponse(429, expectedData)
                    },
                    method: target.method,
                    task: target.task,
                    httpHeaderFields: target.headers
                )
            },
            stubClosure: MoyaProvider.immediatelyStub
        )
        let requester = NetworkingRequester(provider: provider)

        do {
            _ = try await requester.execute(
                request: CatInformationTarget.getBreeds(page: 0, limit: 10)
            )
            Issue.record("Expected the request to fail")
        } catch NetworkError.serverError(let statusCode, let data) {
            #expect(statusCode == 429)
            #expect(data == expectedData)
        } catch {
            Issue.record("Expected serverError, received \(error)")
        }
    }

    private static let breedsFixture = Data(
        #"""
        [
          {
            "id": "abys",
            "name": "Abyssinian",
            "description": "The Abyssinian is easy to care for.",
            "origin": "Egypt",
            "temperament": "Active, Energetic, Independent",
            "life_span": "14 - 15",
            "reference_image_id": "0XYvRd7oD",
            "image": {
              "id": "0XYvRd7oD",
              "url": "https://cdn2.thecatapi.com/images/0XYvRd7oD.jpg",
              "width": 1204,
              "height": 1445
            }
          }
        ]
        """#.utf8
    )

    private static let nullableBreedFixture = Data(
        #"""
        [
          {
            "id": "cara",
            "name": "Caracat",
            "description": null,
            "origin": null,
            "temperament": null,
            "life_span": null,
            "reference_image_id": null,
            "image": null
          }
        ]
        """#.utf8
    )
}

private struct Pagination: Equatable, Sendable {
    let page: Int
    let limit: Int
}

private actor NetworkingRequesterStub: NetworkingRequesterType {
    private let result: Result<Data, NetworkError>
    private var pagination: Pagination?

    init(result: Result<Data, NetworkError>) {
        self.result = result
    }

    var capturedPagination: Pagination? {
        pagination
    }

    func execute(request: any NetworkingTargetType) async throws -> Data {
        if let target = request as? CatInformationTarget,
           case let .getBreeds(page, limit) = target {
            pagination = Pagination(page: page, limit: limit)
        }

        return try result.get()
    }
}
