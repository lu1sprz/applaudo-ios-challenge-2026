# Solution

## Phase 0 — Project stabilization

Before implementing product features, the project setup was reviewed and stabilized against the toolchain range required by the challenge.

### Deployment target

The challenge requires Xcode 26.1.1 through the latest available version, but it does not define a minimum supported iOS version. The application, networking module, and their test targets therefore use iOS 26.0 as their explicit deployment target.

### Tuist compatibility

The starter project pinned Tuist 4.148.1. With current Xcode versions, that release generated the external Moya and Alamofire package targets with historical deployment targets below the minimum accepted by Xcode. This caused the build to fail before any application code was compiled.

Tuist was upgraded and pinned to version 4.209.0, the latest stable release available when the challenge was implemented. Newer Tuist versions clamp generated Swift package targets to deployment targets supported by the selected Xcode SDK. This resolves the incompatibility while preserving the networking setup supplied by the challenge:

- Moya remains integrated through `Tuist/Package.swift`.
- `NetworkLayer` continues depending on `.external(name: "Moya")`.
- No package-specific deployment-target overrides are required.
- The resolved package versions and revisions remain unchanged; Tuist's newer resolver only normalizes their repository URLs in `Package.resolved`.
- The original README is intentionally left unchanged; `ApplaudoChallenge/mise.toml` is the source of truth for the Tuist version used by the solution.

### Validation

The stabilized setup was validated with Xcode 27 and an iOS 26.3 simulator:

- Tuist 4.209.0 installed and activated successfully through mise.
- Swift package dependencies resolved successfully.
- `tuist generate --no-open` generated the workspace successfully.
- The application and test targets completed `build-for-testing` successfully.
- The application test suite passed its existing test.
- The NetworkLayer test target compiled and executed successfully; the starter suite currently contains no test cases.

Dependency resolution emits non-blocking deprecation warnings for old watchOS platform declarations in third-party package manifests. These warnings do not affect the iOS build.

### Automated setup

The repository root includes a `Makefile` so contributors do not need to remember the individual mise and Tuist commands. Run:

```sh
make setup-project
```

The command installs mise through Homebrew when it is not already available, installs the tool versions pinned by the project, resolves the Swift package dependencies, and generates the Xcode workspace without opening Xcode automatically. If both mise and Homebrew are missing, it stops with an actionable error. Each setup step stops immediately if the previous one fails.

### API configuration

The Cat API development key is defined in a single `ApplaudoChallenge/.env` file. Tuist reads this file during project generation and injects `CAT_API_KEY` into the generated application `Info.plist`; the networking layer retrieves it from `Bundle.main` instead of hardcoding it in source code.

The `.gitignore` entry for `.env` is intentionally commented out so the submitted challenge can include its development configuration and run for reviewers without an additional setup file. The adjacent comment explains that this rule should be enabled in a production repository. This keeps environment configuration separate from implementation code, but it is not presented as secure storage: a credential shipped in a client application can be extracted from the resulting binary. A genuinely secret production credential would require a server-side component.

## Phase 1 — Async networking foundation

The starter networking module remains backed by Moya, but its Combine bridge was replaced with structured concurrency. These API calls produce a single response rather than a stream of values, so an `async throws` service API makes request ownership, cancellation, and error propagation explicit while avoiding publisher state in the SwiftUI presentation layer. Combine is described as preferable rather than mandatory by the challenge; this tradeoff keeps the supplied Moya abstraction while using the concurrency model selected for the solution.

### Breed service

`CatInformationTarget` now supports the paginated `GET /breeds` endpoint with `page` and `limit` query parameters. `CatInformationServiceProtocol` exposes that operation to consumers without exposing Moya, and the response DTOs cover the fields required by the list and detail stories, including optional image metadata.

The requester maps successful data, decoding failures, transport failures, non-2xx HTTP responses, and task cancellation independently. Moya applies status-code validation before invoking its completion closure, so non-2xx responses are also mapped from `MoyaError.response`; otherwise server failures would be misreported as unknown transport errors. Network logging is limited to debug builds and excludes request headers so the API key is not printed to the console.

### Concurrency safety

The first-party project targets compile in Swift 6 language mode. Values that cross concurrency boundaries conform to `Sendable`: request targets, response DTOs, network errors, and the public service contract. The Moya provider itself has no `Sendable` conformance, so it is owned by a `NetworkingRequester` actor instead of being declared unchecked. The only `@unchecked Sendable` type is a private cancellation holder whose mutable state is protected by `NSLock`; it exists solely to bridge Swift task cancellation to Moya's `Cancellable` API.

### Tests

The NetworkLayer suite verifies:

- Decoding a representative breed payload, including snake-case fields and image metadata.
- Forwarding pagination values from the service to its request target.
- Mapping malformed payloads to `NetworkError.decodingFailed`.
- Mapping a stubbed HTTP 429 response from Moya to `NetworkError.serverError` with its status and body preserved.

## Phase 2 — Domain and repository boundary

The application does not expose networking DTOs to its presentation layer. `CatBreedRepositoryProtocol` defines the catalog operation in application terms, while `CatBreedRepository` depends on `CatInformationServiceProtocol` and maps each `CatBreedResponse` into an immutable `CatBreed` domain value.

The domain model conforms to `Identifiable` and `Sendable`. It retains the image resource identifier independently from the optional image URL so a later detail implementation can resolve missing image metadata without leaking the API response shape into the UI. `Hashable` is intentionally deferred until a concrete navigation design requires value-based routing.

Repository tests cover complete DTO mapping, pagination forwarding, absent image metadata, and service-error propagation. The service dependency is an actor-based fake, so the tests exercise the same `Sendable` contract used by production code under Swift 6.

## Phase 3 — Observable presentation state

`CatListViewModel` uses the Observation framework and is isolated to `MainActor`. It exposes immutable-from-the-outside breeds and a finite state covering idle, initial loading, loaded, empty, and error outcomes. Its repository dependency remains a private immutable value and therefore does not need `@ObservationIgnored`; only mutable implementation details would require that wrapper.

Loading is exposed as an async operation instead of creating an unstructured task inside the ViewModel. This lets SwiftUI's `.task` modifier own cancellation. Duplicate and repeated initial requests are rejected by the state machine, while retry is accepted only from the error state. Technical failures are converted into a stable user-facing message, and task cancellation restores a non-error state.

Five ViewModel tests cover the loading transition, successful content, empty content, failure, retry, pagination arguments, and duplicate-request prevention with actor-based repository fakes.

## Phase 4 — Breed list UI

The first tab now renders `CatListView` inside its existing navigation stack. The screen switches exhaustively over the ViewModel state and displays a progress indicator, a lazy scrollable list, the supplied `EmptyStateView`, or an actionable retry state. Breed rows reuse `AppCard`; the component was extended with an optional subtitle line limit so API descriptions remain brief without changing existing callers.

`ApplaudoChallengeApp` is the composition root. It creates the concrete service and repository once, owns the Observation ViewModel through `@State`, and injects it through `ContentView` into the feature view. Preview dependencies remain deterministic and do not call the live API.

Detail navigation is deliberately not represented by a placeholder screen. Rows remain non-navigating and omit the chevron until the real detail destination is implemented in the next phase.
