import UIKit

// MARK: - ScheduleViewController

final class ScheduleViewController: UIViewController {

    private enum Layout {
        static let sideInset: CGFloat = 16
        static let rowHeight: CGFloat = 75
        static let tableTopInset: CGFloat = 24
        static let cornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 60
        static let buttonBottomInset: CGFloat = 16
    }

    private let viewModel: ScheduleViewModel

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let doneButton = UIButton(type: .system)

    init(viewModel: ScheduleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP White")
        title = "Расписание"
        navigationItem.hidesBackButton = true

        setupTableView()
        setupDoneButton()
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ScheduleCell.self, forCellReuseIdentifier: ScheduleCell.reuseIdentifier)
        tableView.backgroundColor = UIColor(named: "YP Background")
        tableView.layer.cornerRadius = Layout.cornerRadius
        tableView.layer.masksToBounds = true
        tableView.isScrollEnabled = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Layout.sideInset, bottom: 0, right: Layout.sideInset)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.tableTopInset),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            tableView.heightAnchor.constraint(equalToConstant: Layout.rowHeight * CGFloat(viewModel.days.count))
        ])
    }

    private func setupDoneButton() {
        doneButton.setTitle("Готово", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        doneButton.setTitleColor(UIColor(named: "YP White"), for: .normal)
        doneButton.backgroundColor = UIColor(named: "YP Black")
        doneButton.layer.cornerRadius = Layout.cornerRadius
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        doneButton.accessibilityIdentifier = "schedule done"
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)
        NSLayoutConstraint.activate([
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset + 4),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(Layout.sideInset + 4)),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.buttonBottomInset),
            doneButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }

    @objc private func didTapDone() {
        viewModel.didTapDone()
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ScheduleViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.days.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ScheduleCell.reuseIdentifier,
            for: indexPath
        ) as? ScheduleCell else {
            return UITableViewCell()
        }

        let day = viewModel.days[indexPath.row]
        cell.configure(day: day, isOn: viewModel.isSelected(day))
        cell.onSwitchChanged = { [weak self] isOn in
            self?.viewModel.setDay(day, isOn: isOn)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ScheduleViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Layout.rowHeight
    }
}
