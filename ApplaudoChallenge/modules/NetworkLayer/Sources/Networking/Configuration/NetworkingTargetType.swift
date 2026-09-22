//
//  NetworkingTargetType.swift
//  ApplaudoChallenge
//
//  Created by Christian Rivera on 25/3/26.
//

import Foundation
import Moya

// MARK: - Networking Target Type
/// Describes a network endpoint. Conform to this protocol to define API targets.
/// Each `request*` property maps to the corresponding Moya `TargetType` requirement.
protocol NetworkingTargetType: TargetType, Sendable {
    var requestBaseURL: URL { get }
    var requestPath: String { get }
    var requestHeaders: [String: String]? { get }
    var requestMethod: RequestMethod { get }
    var requestSampleData: Data { get } // Return representative mock JSON for unit tests.
    var cachePolicy: URLRequest.CachePolicy { get }
}

// MARK: - Networking Target Type Default Configuration
/// Shared defaults for all endpoints. Override individual properties in your target only when needed.
extension NetworkingTargetType {

    private var catAPIKey: String {
        Bundle.main.object(forInfoDictionaryKey: "CAT_API_KEY") as? String ?? ""
    }

    // MARK: - Request Base URL
    // Shared across all endpoints; override per-target only if you need a different host.
    var requestBaseURL: URL {
        return URL(string: "https://api.thecatapi.com/v1/")!
    }

    // MARK: - Request Headers
    // Common headers sent with every request. Add or override additional headers in your target as required.
    var requestHeaders: [String: String]? {
        [
            "Content-Type": "application/json",
            "x-api-key": catAPIKey
        ]
    }

    // MARK: - Request Sample Data
    var requestSampleData: Data {
        Data()
    }
}

// MARK: - Networking Library Configuration
/// Bridges the custom `request*` properties to the Moya `TargetType` interface.
/// These computed properties should not need modification; update their `request*` counterparts instead.
extension NetworkingTargetType {
    // MARK: - Moya Base URL
    var baseURL: URL {
        requestBaseURL
    }

    // MARK: - Moya Path
    var path: String {
        requestPath
    }

    // MARK: - Moya Headers
    var headers: [String: String]? {
        requestHeaders
    }

    // MARK: - Moya Method
    var method: Moya.Method {
        // Translates the custom RequestMethod enum to Moya's Method type.
        switch requestMethod {
        case .get: return .get
        case .patch: return .patch
        case .post: return .post
        case .put: return .put
        case .delete: return .delete
        }
    }

    // MARK: - Moya Sample Data
    var sampleData: Data {
        requestSampleData
    }

    var validationType: ValidationType {
        .successCodes // Only 2XX status codes are treated as successful responses.
    }

    var cachePolicy: URLRequest.CachePolicy {
        .reloadIgnoringLocalCacheData // Always fetch fresh data; bypass the local URL cache.
    }
}

// MARK: - Parameters Functions
/// Convenience helper to encode an `Encodable` model into a `[String: Any]` dictionary,
/// suitable for use as URL query parameters or a JSON request body task.
extension NetworkingTargetType {
    func parametersAsDictionary<T: Encodable>(_ parameters: T,
                                              with encoder: JSONEncoder = JSONEncoder()) -> [String: Any] {
        // Falls back to an empty dictionary if encoding fails — handle this case in your target if needed.
        encoder.encodeAsDictionary(parameters) ?? [:]
    }
}
