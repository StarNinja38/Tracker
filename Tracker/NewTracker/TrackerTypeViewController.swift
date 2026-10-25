import UIKit

// MARK: - TrackerType

enum TrackerType {
    case habit
    case irregularEvent

    var screenTitle: String {
        switch self {
        case .habit: return "Новая привычка"
        case .irregularEvent: return "Новое нерегулярное событие"
        }
    }
}

// MARK: - TrackerTypeViewController

final class TrackerTypeViewController: UIViewController {

    private enum Layout {
        static let sideInset: CGFloat = 20
        static let buttonHeight: CGFloat = 60
        static let buttonSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 16
    }

    var onCreate: ((Tracker, String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypWhite)
        title = "Создание трекера"
        setupButtons()
    }

    private func setupButtons() {
        let habitButton = makeButton(title: "Привычка", identifier: AccessibilityIdentifiers.habitButton)
        habitButton.addTarget(self, action: #selector(didTapHabit), for: .touchUpInside)

        let eventButton = makeButton(title: "Нерегулярное событие", identifier: AccessibilityIdentifiers.irregularEventButton)
        eventButton.addTarget(self, action: #selector(didTapIrregularEvent), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [habitButton, eventButton])
        stack.axis = .vertical
        stack.spacing = Layout.buttonSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            habitButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight),
            eventButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }

    private func makeButton(title: String, identifier: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(resource: .ypWhite), for: .normal)
        button.backgroundColor = UIColor(resource: .ypBlack)
        button.layer.cornerRadius = Layout.cornerRadius
        button.accessibilityIdentifier = identifier
        return button
    }

    @objc private func didTapHabit() {
        showNewTracker(type: .habit)
    }

    @objc private func didTapIrregularEvent() {
        showNewTracker(type: .irregularEvent)
    }

    private func showNewTracker(type: TrackerType) {
        let newTracker = NewTrackerViewController(viewModel: NewTrackerViewModel(type: type))
        newTracker.onCreate = onCreate
        navigationController?.pushViewController(newTracker, animated: true)
    }
}
