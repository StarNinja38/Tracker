import UIKit

// MARK: - StatisticsViewController

/// По заданию спринта 14 вкладка пустая — только заголовок.
final class StatisticsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP White")
        title = "Статистика"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
