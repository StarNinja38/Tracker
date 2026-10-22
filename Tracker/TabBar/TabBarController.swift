import UIKit

// MARK: - TabBarController

/// Две вкладки: «Трекеры» и «Статистика». Вторая по заданию спринта 14 пустая.
final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        let trackersViewController = UINavigationController(rootViewController: TrackersViewController())
        trackersViewController.tabBarItem = UITabBarItem(
            title: "Трекеры",
            // ⚠️ Иконка-заглушка из SF Symbols — замени на ассет из Figma (Icon Store).
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: nil
        )

        let statisticsViewController = UINavigationController(rootViewController: StatisticsViewController())
        statisticsViewController.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "hare.fill"),
            selectedImage: nil
        )

        viewControllers = [trackersViewController, statisticsViewController]
    }

    private func setupAppearance() {
        tabBar.tintColor = UIColor(named: "YP Blue")
        tabBar.unselectedItemTintColor = UIColor(named: "YP Gray")

        // Разделительная линия над таб-баром, как в макете.
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "YP White")
        appearance.shadowColor = UIColor(named: "YP LightGray")
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
