import UIKit

// MARK: - StatisticsViewController

final class StatisticsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP White")
        title = "Статистика"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
