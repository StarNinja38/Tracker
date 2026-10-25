import UIKit

// MARK: - FiltersViewController

final class FiltersViewController: UIViewController {

    private enum Layout {
        static let sideInset: CGFloat = 16
        static let rowHeight: CGFloat = 75
        static let tableTopInset: CGFloat = 24
        static let cornerRadius: CGFloat = 16
    }

    private let viewModel: FiltersViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(viewModel: FiltersViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(resource: .ypWhite)
        title = "Фильтры"
        setupTableView()
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.rowHeight = Layout.rowHeight
        tableView.isScrollEnabled = false
        tableView.separatorColor = UIColor(resource: .ypGray)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Layout.sideInset, bottom: 0, right: Layout.sideInset)
        tableView.layer.cornerRadius = Layout.cornerRadius
        tableView.layer.masksToBounds = true
        tableView.accessibilityIdentifier = AccessibilityIdentifiers.filtersTable
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.tableTopInset),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            tableView.heightAnchor.constraint(equalToConstant: Layout.rowHeight * CGFloat(viewModel.filters.count))
        ])
    }
}

// MARK: - UITableViewDataSource

extension FiltersViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filters.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.reuseIdentifier,
            for: indexPath
        ) as? CategoryCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.cellViewModel(at: indexPath.row))
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FiltersViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLast = indexPath.row == viewModel.filters.count - 1
        cell.separatorInset = isLast
            ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: tableView.bounds.width)
            : UIEdgeInsets(top: 0, left: Layout.sideInset, bottom: 0, right: Layout.sideInset)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectFilter(at: indexPath.row)
        dismiss(animated: true)
    }
}
