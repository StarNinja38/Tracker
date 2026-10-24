import Foundation

// MARK: - OnboardingPage

struct OnboardingPage {
    let title: String
    let backgroundImageName: String
}

// MARK: - OnboardingStorage

struct OnboardingStorage {

    private enum Keys {
        static let onboardingShown = "onboardingShown"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isOnboardingShown: Bool {
        get { defaults.bool(forKey: Keys.onboardingShown) }
        nonmutating set { defaults.set(newValue, forKey: Keys.onboardingShown) }
    }
}

// MARK: - OnboardingViewModel

final class OnboardingViewModel {

    var onPageChange: Binding<Int>?
    var onFinish: (() -> Void)?

    let pages = [
        OnboardingPage(title: "Отслеживайте только то, что хотите", backgroundImageName: "onboarding_blue"),
        OnboardingPage(title: "Даже если это не литры воды и йога", backgroundImageName: "onboarding_red")
    ]

    let buttonTitle = "Вот это технологии!"

    private let storage: OnboardingStorage

    init(storage: OnboardingStorage = OnboardingStorage()) {
        self.storage = storage
    }

    // листаем по кругу как в макете
    func indexBefore(_ index: Int) -> Int {
        (index - 1 + pages.count) % pages.count
    }

    func indexAfter(_ index: Int) -> Int {
        (index + 1) % pages.count
    }

    func didShowPage(at index: Int) {
        guard pages.indices.contains(index) else { return }
        onPageChange?(index)
    }

    func didTapFinish() {
        storage.isOnboardingShown = true
        onFinish?()
    }
}
