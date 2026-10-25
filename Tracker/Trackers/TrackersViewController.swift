import UIKit

// MARK: - TrackersViewController

final class TrackersViewController: UIViewController {

    private enum Layout {
        static let sideInset: CGFloat = 16
        static let interitemSpacing: CGFloat = 9
        static let lineSpacing: CGFloat = 0
        static let cellHeight: CGFloat = 148
        static let headerHeight: CGFloat = 54
        static let placeholderImageSize: CGFloat = 80
        static let placeholderSpacing: CGFloat = 8
        static let placeholderCenterOffset: CGFloat = 30
    }

    private let viewModel: TrackersViewModel

    private var visibleCategories: [TrackerCategory] = []

    private let datePicker = UIDatePicker()
    private let searchController = UISearchController(searchResultsController: nil)
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private let placeholderImageView = UIImageView()
    private let placeholderLabel = UILabel()

    init(viewModel: TrackersViewModel = TrackersViewModel()) {
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

        setupNavigationBar()
        setupCollectionView()
        setupPlaceholder()
        bind()
        viewModel.loadData()
    }

    private func bind() {
        viewModel.onVisibleCategoriesChange = { [weak self] categories in
            self?.visibleCategories = categories
            self?.collectionView.reloadData()
        }
        viewModel.onPlaceholderChange = { [weak self] text in
            self?.setPlaceholder(text: text)
        }
        viewModel.onErrorStateChange = { [weak self] message in
            self?.showError(message: message)
        }
    }

    private func setPlaceholder(text: String?) {
        let isEmpty = text != nil
        placeholderLabel.text = text
        placeholderImageView.isHidden = !isEmpty
        placeholderLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setupNavigationBar() {
        title = "Трекеры"
        navigationController?.navigationBar.prefersLargeTitles = true

        // обычный UIBarButtonItem рисует круглый фон, а в макете его нет
        let addButton = UIButton(type: .system)
        addButton.setImage(
            UIImage(systemName: SystemImage.plus, withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .bold)),
            for: .normal
        )
        addButton.tintColor = UIColor(resource: .ypBlack)
        addButton.accessibilityIdentifier = AccessibilityIdentifiers.addTrackerButton
        addButton.addTarget(self, action: #selector(didTapAddTracker), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: addButton)

        datePicker.preferredDatePickerStyle = .compact
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.date = viewModel.currentDate
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)

        // TODO: поиск сделаю в следующем спринте
        searchController.searchBar.placeholder = "Поиск"
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        collectionView.register(
            TrackerCategoryHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TrackerCategoryHeaderView.reuseIdentifier
        )
        collectionView.accessibilityIdentifier = AccessibilityIdentifiers.trackersCollection
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupPlaceholder() {
        placeholderImageView.image = UIImage(resource: .placeholderStar)
        placeholderImageView.contentMode = .scaleAspectFit
        placeholderImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderImageView)

        placeholderLabel.font = .systemFont(ofSize: 12, weight: .medium)
        placeholderLabel.textColor = UIColor(resource: .ypBlack)
        placeholderLabel.textAlignment = .center
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            placeholderImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: Layout.placeholderCenterOffset),
            placeholderImageView.widthAnchor.constraint(equalToConstant: Layout.placeholderImageSize),
            placeholderImageView.heightAnchor.constraint(equalToConstant: Layout.placeholderImageSize),

            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor, constant: Layout.placeholderSpacing)
        ])
    }

    @objc private func didTapAddTracker() {
        let trackerType = TrackerTypeViewController()
        trackerType.onSave = { [weak self] tracker, categoryTitle in
            self?.viewModel.addTracker(tracker, toCategoryWithTitle: categoryTitle)
        }
        let navigationController = UINavigationController(rootViewController: trackerType)
        present(navigationController, animated: true)
    }

    @objc private func dateChanged() {
        viewModel.didChangeDate(datePicker.date)
    }

    private func editTracker(at indexPath: IndexPath) {
        guard let editViewModel = viewModel.makeEditViewModel(at: indexPath) else { return }
        let editViewController = NewTrackerViewController(viewModel: editViewModel)
        editViewController.onSave = { [weak self] tracker, categoryTitle in
            self?.viewModel.updateTracker(tracker, categoryTitle: categoryTitle)
        }
        present(UINavigationController(rootViewController: editViewController), animated: true)
    }

    private func confirmDeleteTracker(at indexPath: IndexPath) {
        guard let trackerId = viewModel.trackerId(at: indexPath) else { return }
        let alert = UIAlertController(
            title: nil,
            message: "Уверены что хотите удалить трекер?",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteTracker(id: trackerId)
        })
        alert.addAction(UIAlertAction(title: "Отменить", style: .cancel))
        present(alert, animated: true)
    }

    private func cardPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard
            let indexPath = configuration.identifier as? IndexPath,
            let cell = collectionView.cellForItem(at: indexPath) as? TrackerCell
        else { return nil }
        return UITargetedPreview(view: cell.previewView)
    }
}

// MARK: - UICollectionViewDataSource

extension TrackersViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        visibleCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleCategories[section].trackers.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TrackerCell.reuseIdentifier,
                for: indexPath
            ) as? TrackerCell,
            let cellViewModel = viewModel.cellViewModel(at: indexPath)
        else {
            return UICollectionViewCell()
        }

        cell.delegate = self
        cell.configure(
            with: cellViewModel.tracker,
            isCompleted: cellViewModel.isCompleted,
            completedDays: cellViewModel.completedDays,
            isEnabled: cellViewModel.isEnabled
        )
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard
            kind == UICollectionView.elementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TrackerCategoryHeaderView.reuseIdentifier,
                for: indexPath
            ) as? TrackerCategoryHeaderView
        else {
            return UICollectionReusableView()
        }
        header.configure(title: visibleCategories[indexPath.section].title)
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TrackersViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else { return nil }
        let pinTitle = viewModel.pinActionTitle(at: indexPath)
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) { [weak self] _ in
            UIMenu(children: [
                UIAction(title: pinTitle) { _ in
                    self?.viewModel.didTogglePin(at: indexPath)
                },
                UIAction(title: "Редактировать") { _ in
                    self?.editTracker(at: indexPath)
                },
                UIAction(title: "Удалить", attributes: .destructive) { _ in
                    self?.confirmDeleteTracker(at: indexPath)
                }
            ])
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfiguration configuration: UIContextMenuConfiguration,
        highlightPreviewForItemAt indexPath: IndexPath
    ) -> UITargetedPreview? {
        cardPreview(for: configuration)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfiguration configuration: UIContextMenuConfiguration,
        dismissalPreviewForItemAt indexPath: IndexPath
    ) -> UITargetedPreview? {
        cardPreview(for: configuration)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        // две карточки в ряд
        let availableWidth = collectionView.bounds.width - Layout.sideInset * 2 - Layout.interitemSpacing
        return CGSize(width: availableWidth / 2, height: Layout.cellHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: Layout.sideInset, bottom: 16, right: Layout.sideInset)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        Layout.interitemSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        Layout.lineSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: Layout.headerHeight)
    }
}

// MARK: - TrackerCellDelegate

extension TrackersViewController: TrackerCellDelegate {

    func trackerCellDidTapPlus(_ cell: TrackerCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        viewModel.didTapComplete(at: indexPath)
    }
}
