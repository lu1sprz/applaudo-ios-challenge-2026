import Foundation
import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("26.0")
let catAPIKey = environmentValue(named: "CAT_API_KEY")

private func environmentValue(named name: String) -> String {
    let environmentURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent(".env")

    guard let contents = try? String(contentsOf: environmentURL, encoding: .utf8) else {
        fatalError("Missing .env file at \(environmentURL.path)")
    }

    for line in contents.components(separatedBy: .newlines) {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        guard !trimmedLine.isEmpty, !trimmedLine.hasPrefix("#") else { continue }

        let components = trimmedLine.split(
            separator: "=",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )

        guard components.count == 2,
              components[0].trimmingCharacters(in: .whitespaces) == name else {
            continue
        }

        return components[1]
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    fatalError("Missing \(name) in .env")
}

let project = Project(
    name: "ApplaudoChallenge",
    targets: [
        .target(
            name: "ApplaudoChallenge",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.ApplaudoChallenge",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CAT_API_KEY": .string(catAPIKey),
                ]
            ),
            buildableFolders: [
                "ApplaudoChallenge/Sources",
                "ApplaudoChallenge/Resources",
            ],
            dependencies: [
                .target(name: "NetworkLayer"),
            ]
        ),
        .target(
            name: "ApplaudoChallengeTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.ApplaudoChallengeTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            buildableFolders: [
                "ApplaudoChallenge/Tests"
            ],
            dependencies: [.target(name: "ApplaudoChallenge")]
        ),
        .target(
            name: "NetworkLayer",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "dev.tuist.NetworkLayer",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            buildableFolders: [
                "modules/NetworkLayer/Sources",
            ],
            dependencies: [
                .external(name: "Moya"),
            ]
        ),
        .target(
            name: "NetworkLayerTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.NetworkLayerTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(
                with: ["CAT_API_KEY": .string(catAPIKey)]
            ),
            buildableFolders: [
                "modules/NetworkLayer/NetworkLayerTest",
            ],
            dependencies: [.target(name: "NetworkLayer")]
        ),
    ]
)
