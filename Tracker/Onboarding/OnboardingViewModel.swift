import Foundation

// MARK: - OnboardingPage

/// Одна страница онбординга: заголовок и фон из Figma.
struct OnboardingPage {
    let title: String
    let backgroundImageName: String
}

// MARK: - OnboardingStorage

/// Помнит, что онбординг уже показан, — при следующем запуске его не будет.
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

/// Вьюмодель онбординга: список страниц, текущая страница для `UIPageControl`
/// и завершение по кнопке «Вот это технологии!».
final class OnboardingViewModel {

    /// Сменилась текущая страница — нужно обновить `UIPageControl`.
    var onPageChange: Binding<Int>?
    /// Онбординг пройден — пора показать главный экран.
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

    /// Листание зациклено, как в макете: со второй страницы вперёд — снова на первую.
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
