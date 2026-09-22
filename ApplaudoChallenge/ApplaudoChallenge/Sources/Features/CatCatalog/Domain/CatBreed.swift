import Foundation

struct CatBreed: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let origin: String
    let temperament: String
    let lifeSpan: String
    let imageID: String?
    let imageURL: URL?
}
