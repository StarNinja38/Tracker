import UIKit

// MARK: - CategoryListViewController

final class CategoryListViewController: UIViewController {

    private enum Layout {
        static let sideInset: CGFloat = 16
        static let rowHeight: CGFloat = 75
        static let tableTopInset: CGFloat = 24
        static let cornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 60
        static let buttonSideInset: CGFloat = 20
        static let buttonBottomInset: CGFloat = 16
        static let placeholderImageSize: CGFloat = 80
        static let placeholderSpacing: CGFloat = 8
    }

    private let viewModel: CategoryListViewModel

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let addButton = UIButton(type: .system)
    private let placeholderImageView = UIImageView()
    private let placeholderLabel = UILabel()

    init(viewModel: CategoryListViewModel) {
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
        title = "Категория"
        navigationItem.hidesBackButton = true

        setupAddButton()
        setupTableView()
        setupPlaceholder()
        bind()
        viewModel.loadCategories()
    }

    private func bind() {
        viewModel.onCategoriesChange = { [weak self] _ in
            self?.updateUI()
        }
        viewModel.onErrorStateChange = { [weak self] message in
            guard let message else { return }
            self?.showError(message: message)
        }
    }

    private func updateUI() {
        let isEmpty = viewModel.isEmpty
        tableView.isHidden = isEmpty
        placeholderImageView.isHidden = !isEmpty
        placeholderLabel.isHidden = !isEmpty
        tableView.reloadData()
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setupAddButton() {
        addButton.setTitle("Добавить категорию", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addButton.setTitleColor(UIColor(named: "YP White"), for: .normal)
        addButton.backgroundColor = UIColor(named: "YP Black")
        addButton.layer.cornerRadius = Layout.cornerRadius
        addButton.addTarget(self, action: #selector(didTapAddCategory), for: .touchUpInside)
        addButton.accessibilityIdentifier = "add category"
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.buttonSideInset),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.buttonSideInset),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.buttonBottomInset),
            addButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.rowHeight = Layout.rowHeight
        tableView.separatorColor = UIColor(named: "YP Gray")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Layout.sideInset, bottom: 0, right: Layout.sideInset)
        tableView.tableFooterView = UIView()
        tableView.showsVerticalScrollIndicator = false
        tableView.accessibilityIdentifier = "categories table"
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.tableTopInset),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sideInset),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sideInset),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -Layout.buttonBottomInset)
        ])
    }

    private func setupPlaceholder() {
        placeholderImageView.image = UIImage(named: "placeholder_star")
        placeholderImageView.contentMode = .scaleAspectFit
        placeholderImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderImageView)

        placeholderLabel.text = "Привычки и события можно\nобъединить по смыслу"
        placeholderLabel.font = .systemFont(ofSize: 12, weight: .medium)
        placeholderLabel.textColor = UIColor(named: "YP Black")
        placeholderLabel.textAlignment = .center
        placeholderLabel.numberOfLines = 0
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            placeholderImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            placeholderImageView.widthAnchor.constraint(equalToConstant: Layout.placeholderImageSize),
            placeholderImageView.heightAnchor.constraint(equalToConstant: Layout.placeholderImageSize),

            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor, constant: Layout.placeholderSpacing)
        ])
    }

    @objc private func didTapAddCategory() {
        let form = CategoryFormViewController(viewModel: viewModel.makeNewCategoryViewModel())
        navigationController?.pushViewController(form, animated: true)
    }

    private func editCategory(at index: Int) {
        guard let formViewModel = viewModel.makeEditCategoryViewModel(at: index) else { return }
        navigationController?.pushViewController(CategoryFormViewController(viewModel: formViewModel), animated: true)
    }

    private func confirmDeleteCategory(at index: Int) {
        let alert = UIAlertController(
            title: nil,
            message: "Эта категория точно не нужна?",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCategory(at: index)
        })
        alert.addAction(UIAlertAction(title: "Отменить", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CategoryListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.reuseIdentifier,
            for: indexPath
        ) as? CategoryCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.categories[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension CategoryListViewController: UITableViewDelegate {

    // скругляю первую и последнюю ячейку, у последней убираю разделитель
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == viewModel.categories.count - 1

        var corners: CACornerMask = []
        if isFirst { corners.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if isLast { corners.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
        cell.layer.cornerRadius = corners.isEmpty ? 0 : Layout.cornerRadius
        cell.layer.maskedCorners = corners
        cell.layer.masksToBounds = true

        cell.separatorInset = isLast
            ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: tableView.bounds.width)
            : UIEdgeInsets(top: 0, left: Layout.sideInset, bottom: 0, right: Layout.sideInset)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectCategory(at: indexPath.row)
        navigationController?.popViewController(animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let index = indexPath.row
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            UIMenu(children: [
                UIAction(title: "Редактировать") { _ in
                    self?.editCategory(at: index)
                },
                UIAction(title: "Удалить", attributes: .destructive) { _ in
                    self?.confirmDeleteCategory(at: index)
                }
            ])
        })
    }
}
