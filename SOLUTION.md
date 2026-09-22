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
