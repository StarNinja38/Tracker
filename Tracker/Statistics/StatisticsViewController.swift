import UIKit

// MARK: - StatisticsViewController

final class StatisticsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypWhite)
        title = "Статистика"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
