import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private let onboardingStorage = OnboardingStorage()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeRootViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    // онбординг показываем только при первом запуске
    private func makeRootViewController() -> UIViewController {
        guard onboardingStorage.isOnboardingShown else {
            let viewModel = OnboardingViewModel(storage: onboardingStorage)
            viewModel.onFinish = { [weak self] in
                self?.switchToTabBar()
            }
            return OnboardingViewController(viewModel: viewModel)
        }
        return TabBarController()
    }

    private func switchToTabBar() {
        guard let window else { return }
        window.rootViewController = TabBarController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}
