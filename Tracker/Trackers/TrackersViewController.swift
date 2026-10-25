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
        static let filterButtonWidth: CGFloat = 114
        static let filterButtonHeight: CGFloat = 50
        static let filterButtonBottomInset: CGFloat = 16
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
    private let filterButton = UIButton(type: .system)

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
        setupFilterButton()
        bind()
        viewModel.loadData()
    }

    private func bind() {
        viewModel.onVisibleCategoriesChange = { [weak self] categories in
            self?.visibleCategories = categories
            self?.collectionView.reloadData()
        }
        viewModel.onPlaceholderChange = { [weak self] placeholder in
            self?.setPlaceholder(placeholder)
        }
        viewModel.onFilterButtonChange = { [weak self] state in
            self?.filterButton.isHidden = state.isHidden
            self?.filterButton.setTitleColor(state.isActive ? UIColor(resource: .ypRed) : .white, for: .normal)
        }
        viewModel.onDateChange = { [weak self] date in
            self?.datePicker.setDate(date, animated: true)
        }
        viewModel.onErrorStateChange = { [weak self] message in
            self?.showError(message: message)
        }
    }

    private func setPlaceholder(_ placeholder: TrackersPlaceholder?) {
        let isEmpty = placeholder != nil
        placeholderLabel.text = placeholder?.text
        placeholderImageView.image = placeholder == .nothingFound
            ? UIImage(resource: .placeholderNothingFound)
            : UIImage(resource: .placeholderStar)
        placeholderImageView.isHidden = !isEmpty
        placeholderLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: NSLocalizedString("common.error", comment: ""), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setupNavigationBar() {
        title = NSLocalizedString("main.title", comment: "")
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
        datePicker.date = viewModel.currentDate
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)

        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = NSLocalizedString("main.search", comment: "")
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
        // место под кнопкой фильтров, чтобы последние карточки можно было докрутить выше нее
        collectionView.contentInset.bottom = Layout.filterButtonHeight + Layout.filterButtonBottomInset * 2
        collectionView.alwaysBounceVertical = true
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

    private func setupFilterButton() {
        filterButton.setTitle(NSLocalizedString("main.filters", comment: ""), for: .normal)
        filterButton.titleLabel?.font = .systemFont(ofSize: 17)
        filterButton.setTitleColor(.white, for: .normal)
        filterButton.backgroundColor = UIColor(resource: .ypBlue)
        filterButton.layer.cornerRadius = 16
        filterButton.isHidden = true
        filterButton.accessibilityIdentifier = AccessibilityIdentifiers.filtersButton
        filterButton.addTarget(self, action: #selector(didTapFilters), for: .touchUpInside)
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(filterButton)
        NSLayoutConstraint.activate([
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.filterButtonBottomInset),
            filterButton.widthAnchor.constraint(equalToConstant: Layout.filterButtonWidth),
            filterButton.heightAnchor.constraint(equalToConstant: Layout.filterButtonHeight)
        ])
    }

    @objc private func didTapFilters() {
        let filters = FiltersViewController(viewModel: viewModel.makeFiltersViewModel())
        present(UINavigationController(rootViewController: filters), animated: true)
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
            message: NSLocalizedString("alert.deleteTracker", comment: ""),
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("menu.delete", comment: ""), style: .destructive) { [weak self] _ in
            self?.viewModel.deleteTracker(id: trackerId)
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel))
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
                UIAction(title: NSLocalizedString("menu.edit", comment: "")) { _ in
                    self?.editTracker(at: indexPath)
                },
                UIAction(title: NSLocalizedString("menu.delete", comment: ""), attributes: .destructive) { _ in
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

// MARK: - UISearchResultsUpdating

extension TrackersViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.didChangeSearchText(searchController.searchBar.text ?? "")
    }
}
