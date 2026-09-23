import Foundation

struct RegisteredCat: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let name: String
    let breed: String
    let age: Int
    let description: String
    let createdAt: Date
}
