PROJECT_DIRECTORY := ApplaudoChallenge

.PHONY: setup-project ensure-mise

setup-project: ensure-mise
	@echo "Installing the pinned development tools..."
	@cd $(PROJECT_DIRECTORY) && mise install
	@echo "Resolving Swift package dependencies..."
	@cd $(PROJECT_DIRECTORY) && mise exec -- tuist install
	@echo "Generating the Xcode workspace..."
	@cd $(PROJECT_DIRECTORY) && mise exec -- tuist generate --no-open
	@echo "Project setup completed successfully."

ensure-mise:
	@if ! command -v mise >/dev/null 2>&1; then \
		if ! command -v brew >/dev/null 2>&1; then \
			echo "Error: Homebrew is required to install mise. Visit https://brew.sh"; \
			exit 1; \
		fi; \
		echo "mise was not found. Installing it with Homebrew..."; \
		brew install mise; \
	fi
