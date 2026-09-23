# Solution

## Overview

The solution completes the required catalog, breed detail, and local cat-registration stories, as well as pagination and form validation. A third tab makes locally registered cats visible after saving and across application launches.

The implementation uses feature-oriented MVVM, protocol-based boundaries for external dependencies, Swift Observation for presentation state, and Swift concurrency throughout the networking and persistence layers.

## Architecture

The dependency flow is unidirectional:

```text
ApplaudoChallengeApp (composition root)
├── CatListView
│   └── CatListViewModel
│       └── CatBreedRepositoryProtocol
│           └── CatBreedRepository
│               └── CatInformationServiceProtocol
│                   └── Moya-backed NetworkLayer
└── AddCatStepperView / SavedCatsView
    └── AddCatViewModel / SavedCatsViewModel
        └── RegisteredCatRepositoryProtocol
            └── LocalRegisteredCatRepository actor
```

### Composition and ownership

`ApplaudoChallengeApp` is the composition root. It creates the concrete services and repositories, owns the Observation ViewModels through `@State`, and injects them into `ContentView`. This gives the ViewModels a stable application-level lifetime without using singletons or a service locator.

The registration and saved-cats ViewModels receive the same `LocalRegisteredCatRepository` actor. Both features therefore operate on one serialized source of persisted data.

ViewModels remain concrete because each one is a feature-specific presentation implementation that evolves together with its SwiftUI view. Protocols are placed at the boundaries that require substitution: networking services and repositories. Tests exercise the real ViewModels with actor-based fakes for those dependencies.

### Model boundaries

Networking DTOs are confined to `NetworkLayer`. `CatBreedRepository` maps them into immutable `CatBreed` domain values before they reach presentation code. This prevents SwiftUI from depending on the API response shape and provides one place to normalize external data.

The Cat API occasionally returns null descriptive metadata in otherwise successful pages. DTOs reflect that nullability, while the repository supplies safe domain values for missing descriptions, origins, temperaments, and life spans. One incomplete item therefore cannot invalidate an entire page.

## Networking and concurrency

The supplied Moya abstraction was retained, while its Combine-based API was replaced with `async throws`. Breed requests are one-shot operations rather than event streams, so structured concurrency provides a simpler model for ownership and error propagation. The challenge describes Combine as preferable rather than mandatory; Combine would remain appropriate for persistent event streams or multi-source reactive pipelines.

`NetworkingRequester` bridges Moya's completion callback with `withCheckedThrowingContinuation`. Successful responses, non-2xx responses, transport failures, and decoding failures are mapped independently. After Moya completes, `Task.checkCancellation()` prevents a cancelled caller from consuming the result.

First-party targets compile in Swift 6 mode. DTOs, targets, errors, and service contracts are `Sendable`. The non-`Sendable` Moya provider is isolated inside a `NetworkingRequester` actor instead of being exposed through unchecked conformance.

Pagination has separate state from initial loading. Approaching the final five visible items requests the next page while preserving existing content. The ViewModel prevents overlapping loads, retries the same page after failure, removes duplicate IDs, advances only after success, and treats a partial page as the end of the catalog.

Debug network logging omits request headers so the API key is not printed.

## Presentation

Presentation models use `@Observable` and are isolated to `MainActor`. They expose finite UI states rather than independent loading and error booleans, making loading, content, empty, failure, pagination, saving, and confirmation states explicit. Async work is exposed to SwiftUI so `.task` owns its cancellation instead of the ViewModels creating unstructured tasks.

Catalog navigation uses a typed route containing only the breed identifier. The destination resolves the current domain value from the catalog ViewModel, avoiding a `Hashable` requirement on the complete model. `CatBreedDetailView` receives an immutable domain value directly because the read-only screen has no behavior or mutable state that would justify another ViewModel.

The registration flow contains identity, details, and review steps. Validation runs before navigation or submission and displays errors beside the corresponding fields. The saved-cats tab reloads from persistence whenever it is selected, orders entries newest first, and provides loading, content, empty, and failure states. Its empty-state action changes the selected tab to the registration flow.

Existing theme tokens and components are reused. `AppCard` gained configurable subtitle line limits, and `AppTextEditor` extends the component set for multiline input.

## Local persistence

Registered cats are stored as a `Codable` JSON array under Application Support. `LocalRegisteredCatRepository` is an actor, serializing in-process reads and writes, and uses atomic file replacement to avoid partially written data. Its file URL is injectable so persistence can be tested without touching production storage.

JSON was selected because the current dataset is small and append-only, with no relationships, filtering, editing, or deletion. It is more appropriate than `UserDefaults` for structured entities and avoids introducing SwiftData model-container and migration overhead before those capabilities are needed. The repository protocol allows the implementation to be replaced without changing presentation code.

The trade-off is that each save rewrites the complete collection and schema migrations are manual. SwiftData or another database would become preferable if the feature gained editing, deletion, relationships, complex queries, or significantly larger datasets.

## Project setup and configuration

The challenge specifies Xcode 26.1.1 through the latest release but does not require an older deployment target, so all first-party targets explicitly use iOS 26.0.

The starter's Tuist 4.148.1 generated third-party package targets with deployment versions rejected by current Xcode releases. Tuist was updated and pinned to 4.209.0, resolving that compatibility issue without modifying Moya or Alamofire. The original README remains unchanged, while `mise.toml` is the tool-version source of truth.

The repository root provides one setup command:

```sh
make setup-project
```

It ensures mise is available, installs the pinned tools, resolves Swift packages, and generates the workspace without opening Xcode.

The development Cat API key lives in `ApplaudoChallenge/.env` and is injected into the generated `Info.plist` by Tuist. It is included so reviewers can run the submitted project without extra configuration. In a production repository `.env` would be ignored and CI would inject the appropriate environment value. A credential shipped in a client application is configuration, not a true secret; sensitive credentials require a server-side boundary.

## Testing and validation

Unit and integration tests use Swift Testing. Fakes conform to the same `Sendable` protocols as production dependencies, and actors protect mutable test state under Swift 6 concurrency checking.

Coverage includes:

- DTO decoding, nullable metadata, pagination parameters, HTTP errors, and malformed responses.
- Repository mapping, fallback values, and error propagation.
- Initial catalog states, retry, cancellation, pagination, duplicate prevention, and end detection.
- Form validation, normalization, save failures, confirmation, and reset.
- Local persistence across repository instances.
- Saved-cat loading, ordering, empty state, failure, and recovery.

The documented setup was executed from the repository root, followed by both test schemes on an iPhone 18 Pro simulator running iOS 27.0 with Xcode 27:

- 23 application tests passed.
- 4 NetworkLayer tests passed.
- The Xcode test result bundles reported no failures or runtime warnings.

## Trade-offs and assumptions

- Combine was replaced by `async/await` because the implemented network calls produce a single result. This reduces state and subscription-management complexity, at the cost of diverging from the starter's preferred reactive style.
- Cancellation is cooperative at the requester boundary: a cancelled task discards the response after Moya finishes, but it does not cancel the underlying HTTP request. This keeps the callback bridge small and free of manual locking; transport-level cancellation would be worth restoring for uploads, downloads, or otherwise expensive requests.
- Pagination completion is inferred from a page containing fewer items than the requested limit. Returning the API's pagination metadata through the service boundary would be more explicit if pagination rules became more complex.
- JSON persistence assumes a small, local, append-only collection. It intentionally avoids database overhead, but it is not intended for complex queries, relationships, or concurrent access from multiple processes.
- iOS 26.0 is treated as the deployment baseline because the challenge does not request backward compatibility. Supporting earlier systems would require replacing Observation and reviewing availability across the UI.
- The checked-in `.env` is a reviewer convenience, not a security mechanism. A production credential that must remain secret would be held behind a backend service.

## Further improvements

Given more time, the next priorities would be UI tests for the critical navigation and registration journeys, image caching, localization, broader accessibility verification, and editing or deleting registered cats. If the number of composition dependencies grew substantially, the explicit setup in `ApplaudoChallengeApp` could be extracted into a small application container without changing feature-level APIs.
