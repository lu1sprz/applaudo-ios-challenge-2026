import Foundation
import Testing
@testable import ApplaudoChallenge

@MainActor
@Suite("Add cat view model")
struct AddCatViewModelTests {
    @Test("It validates identity before advancing")
    func identityValidation() {
        let viewModel = AddCatViewModel(repository: RegisteredCatRepositoryStub())

        viewModel.next()

        #expect(viewModel.currentStep == .identity)
        #expect(viewModel.nameError == "Name is required.")
        #expect(viewModel.breedError == "Breed is required.")

        viewModel.name = "L"
        viewModel.breed = "Abyssinian"
        viewModel.next()

        #expect(viewModel.currentStep == .identity)
        #expect(viewModel.nameError == "Name must contain at least 2 characters.")

        viewModel.name = "Luna"
        viewModel.next()

        #expect(viewModel.currentStep == .details)
    }

    @Test("It validates details before advancing")
    func detailsValidation() {
        let viewModel = AddCatViewModel(repository: RegisteredCatRepositoryStub())
        advanceToDetails(viewModel)

        viewModel.age = "0"
        viewModel.catDescription = "Short"
        viewModel.next()

        #expect(viewModel.currentStep == .details)
        #expect(viewModel.ageError == "Age must be a positive whole number.")
        #expect(viewModel.descriptionError == "Description must contain at least 10 characters.")

        viewModel.age = "3"
        viewModel.catDescription = "Curious and playful."
        viewModel.next()

        #expect(viewModel.currentStep == .review)
    }

    @Test("It saves a normalized cat and displays confirmation")
    func save() async throws {
        let repository = RegisteredCatRepositoryStub()
        let viewModel = AddCatViewModel(repository: repository)
        completeValidForm(viewModel)

        await viewModel.save()

        let savedCat = try #require(await repository.savedCats.first)
        #expect(savedCat.name == "Luna")
        #expect(savedCat.breed == "Abyssinian")
        #expect(savedCat.age == 3)
        #expect(savedCat.description == "Curious and playful.")
        #expect(viewModel.state == .saved(savedCat))
    }

    @Test("It exposes a retryable save error")
    func saveFailure() async {
        let repository = RegisteredCatRepositoryStub(saveError: .unavailable)
        let viewModel = AddCatViewModel(repository: repository)
        completeValidForm(viewModel)

        await viewModel.save()

        #expect(
            viewModel.state == .error(
                message: "We couldn't save this cat. Please try again."
            )
        )
        #expect(viewModel.currentStep == .review)

        viewModel.previous()

        #expect(viewModel.state == .editing)
        #expect(viewModel.currentStep == .details)
    }

    @Test("It resets after a successful registration")
    func reset() async {
        let viewModel = AddCatViewModel(repository: RegisteredCatRepositoryStub())
        completeValidForm(viewModel)
        await viewModel.save()

        viewModel.reset()

        #expect(viewModel.state == .editing)
        #expect(viewModel.currentStep == .identity)
        #expect(viewModel.name.isEmpty)
        #expect(viewModel.breed.isEmpty)
        #expect(viewModel.age.isEmpty)
        #expect(viewModel.catDescription.isEmpty)
    }

    private func advanceToDetails(_ viewModel: AddCatViewModel) {
        viewModel.name = "Luna"
        viewModel.breed = "Abyssinian"
        viewModel.next()
    }

    private func completeValidForm(_ viewModel: AddCatViewModel) {
        advanceToDetails(viewModel)
        viewModel.age = "3"
        viewModel.catDescription = "Curious and playful."
        viewModel.next()
    }
}

private enum RegisteredCatRepositoryStubError: Error, Sendable {
    case unavailable
}

private actor RegisteredCatRepositoryStub: RegisteredCatRepositoryProtocol {
    private(set) var savedCats: [RegisteredCat] = []
    private let saveError: RegisteredCatRepositoryStubError?

    init(saveError: RegisteredCatRepositoryStubError? = nil) {
        self.saveError = saveError
    }

    func save(_ cat: RegisteredCat) async throws {
        if let saveError {
            throw saveError
        }

        savedCats.append(cat)
    }

    func fetchAll() async throws -> [RegisteredCat] {
        savedCats
    }
}
