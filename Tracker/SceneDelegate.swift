import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private enum Defaults {
        static let onboardingShown = "onboardingShown"
    }

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

    /// Онбординг показывается один раз — при первом запуске.
    private func makeRootViewController() -> UIViewController {
        guard UserDefaults.standard.bool(forKey: Defaults.onboardingShown) else {
            let onboarding = OnboardingViewController()
            onboarding.onFinish = { [weak self] in
                UserDefaults.standard.set(true, forKey: Defaults.onboardingShown)
                self?.switchToTabBar()
            }
            return onboarding
        }
        return TabBarController()
    }

    private func switchToTabBar() {
        guard let window else { return }
        window.rootViewController = TabBarController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}
