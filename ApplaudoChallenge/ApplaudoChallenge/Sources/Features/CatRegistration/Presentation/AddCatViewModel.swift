import Foundation
import Observation

@MainActor
@Observable
final class AddCatViewModel {
    enum Step: Int, CaseIterable, Equatable {
        case identity
        case details
        case review
    }

    enum State: Equatable {
        case editing
        case saving
        case saved(RegisteredCat)
        case error(message: String)
    }

    var name = "" {
        didSet {
            nameError = nil
            clearSaveError()
        }
    }
    var breed = "" {
        didSet {
            breedError = nil
            clearSaveError()
        }
    }
    var age = "" {
        didSet {
            ageError = nil
            clearSaveError()
        }
    }
    var catDescription = "" {
        didSet {
            descriptionError = nil
            clearSaveError()
        }
    }

    private(set) var currentStep: Step = .identity
    private(set) var state: State = .editing
    private(set) var nameError: String?
    private(set) var breedError: String?
    private(set) var ageError: String?
    private(set) var descriptionError: String?

    let stepTitles = ["Identity", "Details", "Review"]

    private let repository: any RegisteredCatRepositoryProtocol
    private static let saveFailureMessage = "We couldn't save this cat. Please try again."

    init(repository: any RegisteredCatRepositoryProtocol) {
        self.repository = repository
    }

    var canMoveBack: Bool {
        currentStep != .identity && state != .saving
    }

    var isSaving: Bool {
        state == .saving
    }

    var saveErrorMessage: String? {
        guard case .error(let message) = state else { return nil }
        return message
    }

    func next() {
        switch currentStep {
        case .identity:
            guard validateIdentity() else { return }
            currentStep = .details
        case .details:
            guard validateDetails() else { return }
            currentStep = .review
        case .review:
            break
        }
    }

    func previous() {
        guard canMoveBack,
              let previousStep = Step(rawValue: currentStep.rawValue - 1) else {
            return
        }

        currentStep = previousStep
        clearSaveError()
    }

    func save() async {
        guard currentStep == .review, !isSaving, validateAll() else { return }

        let cat = RegisteredCat(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            breed: breed.trimmingCharacters(in: .whitespacesAndNewlines),
            age: Int(age.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
            description: catDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date()
        )

        state = .saving

        do {
            try await repository.save(cat)
            state = .saved(cat)
        } catch {
            state = .error(message: Self.saveFailureMessage)
        }
    }

    func reset() {
        name = ""
        breed = ""
        age = ""
        catDescription = ""
        currentStep = .identity
        state = .editing
        clearErrors()
    }

    private func validateIdentity() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBreed = breed.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            nameError = "Name is required."
        } else if trimmedName.count < 2 {
            nameError = "Name must contain at least 2 characters."
        }

        if trimmedBreed.isEmpty {
            breedError = "Breed is required."
        }

        return nameError == nil && breedError == nil
    }

    private func validateDetails() -> Bool {
        let trimmedAge = age.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = catDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedAge.isEmpty {
            ageError = "Age is required."
        } else if let value = Int(trimmedAge), value > 0 {
            ageError = nil
        } else {
            ageError = "Age must be a positive whole number."
        }

        if trimmedDescription.isEmpty {
            descriptionError = "Description is required."
        } else if trimmedDescription.count < 10 {
            descriptionError = "Description must contain at least 10 characters."
        }

        return ageError == nil && descriptionError == nil
    }

    private func validateAll() -> Bool {
        let identityIsValid = validateIdentity()
        let detailsAreValid = validateDetails()
        return identityIsValid && detailsAreValid
    }

    private func clearErrors() {
        nameError = nil
        breedError = nil
        ageError = nil
        descriptionError = nil
    }

    private func clearSaveError() {
        if case .error = state {
            state = .editing
        }
    }
}
