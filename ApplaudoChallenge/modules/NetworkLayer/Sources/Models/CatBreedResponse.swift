import Foundation

public struct CatBreedResponse: Decodable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let origin: String
    public let temperament: String
    public let lifeSpan: String
    public let referenceImageID: String?
    public let image: CatImageResponse?

    public init(
        id: String,
        name: String,
        description: String,
        origin: String,
        temperament: String,
        lifeSpan: String,
        referenceImageID: String?,
        image: CatImageResponse?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.origin = origin
        self.temperament = temperament
        self.lifeSpan = lifeSpan
        self.referenceImageID = referenceImageID
        self.image = image
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case origin
        case temperament
        case lifeSpan = "life_span"
        case referenceImageID = "reference_image_id"
        case image
    }
}

public struct CatImageResponse: Decodable, Equatable, Sendable {
    public let id: String
    public let url: URL
    public let width: Int
    public let height: Int

    public init(id: String, url: URL, width: Int, height: Int) {
        self.id = id
        self.url = url
        self.width = width
        self.height = height
    }
}
