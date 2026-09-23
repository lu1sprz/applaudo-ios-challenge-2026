//
//  NetworkingRequester.swift
//  ApplaudoChallenge
//
//  Created by Christian Rivera on 25/3/26.
//

import Foundation
import Moya

// MARK: - Network Error
/// Lightweight domain error type that wraps common networking failures.
/// Candidates can extend this enum with additional cases as needed.
public enum NetworkError: Error, LocalizedError, Sendable {
    /// The server returned an unexpected status code.
    case serverError(statusCode: Int, data: Data)
    /// The response data could not be decoded into the expected type.
    case decodingFailed(underlying: Error)
    /// A generic/unknown failure.
    case unknown(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .serverError(let code, _):
            return "Server returned status code \(code)."
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Networking Requester Type
/// Core networking abstraction. Any type conforming to this protocol can execute API requests.
/// Implement `execute` to drive the full request lifecycle using the provided `NetworkingTargetType`.
protocol NetworkingRequesterType: Sendable {
    /// Executes a network request and returns its raw response data.
    /// - Parameter request: The endpoint descriptor conforming to `NetworkingTargetType`.
    func execute(request: any NetworkingTargetType) async throws -> Data
}

// MARK: - Networking Requester
/// Concrete implementation of `NetworkingRequesterType` backed by a Moya `MoyaProvider<MultiTarget>`.
actor NetworkingRequester: NetworkingRequesterType {
    // MARK: - Properties
    private let provider: MoyaProvider<MultiTarget>

    // MARK: - Initializer
    init(
        provider: MoyaProvider<MultiTarget>
    ) {
        self.provider = provider
    }

    func execute(request: any NetworkingTargetType) async throws -> Data {
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            provider.request(MultiTarget(request)) { result in
                switch result {
                case .success(let response):
                    guard (200...299).contains(response.statusCode) else {
                        continuation.resume(
                            throwing: NetworkError.serverError(
                                statusCode: response.statusCode,
                                data: response.data
                            )
                        )
                        return
                    }

                    continuation.resume(returning: response.data)
                case .failure(let error):
                    if let response = error.response,
                       !(200...299).contains(response.statusCode) {
                        continuation.resume(
                            throwing: NetworkError.serverError(
                                statusCode: response.statusCode,
                                data: response.data
                            )
                        )
                    } else {
                        continuation.resume(throwing: NetworkError.unknown(underlying: error))
                    }
                }
            }
        }

        try _Concurrency.Task<Never, Never>.checkCancellation()
        return data
    }
}

// MARK: - Default Implementation
/// Convenience overload that decodes the raw response into a `Decodable` value.
extension NetworkingRequesterType {
    /// - Parameters:
    ///   - request: The endpoint descriptor.
    ///   - decoder: `JSONDecoder` to use; defaults to a standard instance.
    func execute<T: Decodable & Sendable>(
        request: any NetworkingTargetType,
        using decoder: JSONDecoder = .init()
    ) async throws -> T {
        let data = try await execute(request: request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlying: error)
        }
    }
}
