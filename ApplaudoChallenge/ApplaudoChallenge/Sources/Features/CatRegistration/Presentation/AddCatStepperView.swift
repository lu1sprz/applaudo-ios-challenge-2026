import SwiftUI

struct AddCatStepperView: View {
    @Bindable var viewModel: AddCatViewModel

    var body: some View {
        Group {
            if case .saved(let cat) = viewModel.state {
                confirmationView(for: cat)
            } else {
                formView
            }
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Add Cat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                StepperIndicator(
                    currentStep: viewModel.currentStep.rawValue,
                    totalSteps: AddCatViewModel.Step.allCases.count,
                    stepTitles: viewModel.stepTitles
                )
                .padding(.top, AppTheme.Spacing.sm)

                currentStepContent

                if let saveErrorMessage = viewModel.saveErrorMessage {
                    Label(saveErrorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(AppTheme.Fonts.caption)
                        .foregroundStyle(AppTheme.Colors.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                navigationButtons
            }
            .padding(AppTheme.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var currentStepContent: some View {
        switch viewModel.currentStep {
        case .identity:
            identityStep
        case .details:
            detailsStep
        case .review:
            reviewStep
        }
    }

    private var identityStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            SectionHeader(
                title: "Meet Your Cat",
                subtitle: "Start with the basic information",
                systemImage: "cat.fill"
            )

            AppTextField(
                label: "Name",
                placeholder: "e.g. Luna",
                text: $viewModel.name,
                errorMessage: viewModel.nameError,
                icon: "textformat"
            )

            AppTextField(
                label: "Breed",
                placeholder: "e.g. Abyssinian",
                text: $viewModel.breed,
                errorMessage: viewModel.breedError,
                icon: "pawprint.fill"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            SectionHeader(
                title: "Cat Details",
                subtitle: "Add a little more context",
                systemImage: "list.bullet.clipboard.fill"
            )

            AppTextField(
                label: "Age",
                placeholder: "Age in years",
                text: $viewModel.age,
                errorMessage: viewModel.ageError,
                keyboardType: .numberPad,
                icon: "calendar"
            )

            AppTextEditor(
                label: "Description",
                placeholder: "Tell us about personality, habits, or favorite activities",
                text: $viewModel.catDescription,
                errorMessage: viewModel.descriptionError
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            SectionHeader(
                title: "Review",
                subtitle: "Confirm everything before saving",
                systemImage: "checkmark.circle.fill"
            )

            VStack(spacing: 0) {
                reviewRow(title: "Name", value: viewModel.name)
                Divider()
                reviewRow(title: "Breed", value: viewModel.breed)
                Divider()
                reviewRow(title: "Age", value: "\(viewModel.age) years")
                Divider()
                reviewRow(title: "Description", value: viewModel.catDescription)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var navigationButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if viewModel.canMoveBack {
                AppButton(
                    title: "Back",
                    style: .secondary,
                    isEnabled: !viewModel.isSaving,
                    action: viewModel.previous
                )
            }

            if viewModel.currentStep == .review {
                AppButton(
                    title: "Save Cat",
                    isEnabled: !viewModel.isSaving,
                    isLoading: viewModel.isSaving,
                    action: {
                        Task { await viewModel.save() }
                    }
                )
            } else {
                AppButton(title: "Continue", action: viewModel.next)
            }
        }
    }

    private func reviewRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Fonts.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Text(value)
                .font(AppTheme.Fonts.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }

    private func confirmationView(for cat: RegisteredCat) -> some View {
        EmptyStateView(
            systemImage: "checkmark.circle.fill",
            title: "Cat Saved",
            message: "\(cat.name) was saved on this device.",
            buttonTitle: "Add Another Cat",
            action: viewModel.reset
        )
        .accessibilityIdentifier("add-cat-confirmation")
    }
}

#Preview {
    NavigationStack {
        AddCatStepperView(
            viewModel: AddCatViewModel(repository: AddCatPreviewRepository())
        )
    }
}

private struct AddCatPreviewRepository: RegisteredCatRepositoryProtocol {
    func save(_ cat: RegisteredCat) async throws {}

    func fetchAll() async throws -> [RegisteredCat] {
        []
    }
}
