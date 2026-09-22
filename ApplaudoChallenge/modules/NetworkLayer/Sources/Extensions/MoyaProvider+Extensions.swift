//
//  MoyaProvider+Extensions.swift
//  ApplaudoChallenge
//
//  Created by Christian Rivera on 26/3/26.
//

import Moya

extension MoyaProvider {
    // MARK: - Custom Networking Provider
    /// Factory method that returns the shared `MoyaProvider<MultiTarget>` used by `NetworkingRequester`.
    /// Modify the session configuration or add plugins here as your networking requirements grow.
    static func networkingProvider() -> MoyaProvider<MultiTarget> {
        // Configure the underlying URLSession; swap `.default` for a custom configuration if needed (e.g., background sessions).
        let networkingSession: Session = .init(configuration: .default)
        #if DEBUG
        // Do not log request headers: they contain the API key.
        let loggerPlugin: PluginType = NetworkLoggerPlugin(
            configuration: .init(logOptions: [.requestMethod, .errorResponseBody])
        )
        let plugins: [PluginType] = [loggerPlugin]
        #else
        let plugins: [PluginType] = []
        #endif

        return MoyaProvider<MultiTarget>(session: networkingSession, plugins: plugins)
    }
}
