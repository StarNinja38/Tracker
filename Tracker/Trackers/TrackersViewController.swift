import UIKit

// MARK: - TrackersViewController

/// Главный экран «Трекеры»: коллекция карточек, сгруппированных по категориям,
/// с выбором даты в правом `NavBarItem` и кнопкой добавления в левом.
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

    private enum Constants {
        /// Пока экран «Категория» не реализован (задание спринта 15),
        /// все новые трекеры складываем в одну категорию.
        static let defaultCategoryTitle = "Важное"
    }

    // MARK: Данные

    /// Все категории с трекерами — источник правды экрана.
    var categories: [TrackerCategory] = []

    /// Записи о выполнении. Массив требуется заданием.
    var completedTrackers: [TrackerRecord] = []

    /// Дубль записей в `Set` — чтобы проверять выполненность за O(1),
    /// а не линейным поиском по массиву.
    private var completedRecords: Set<TrackerRecord> = []

    /// Дата, выбранная в `UIDatePicker`.
    var currentDate: Date = Date()

    /// Категории, попадающие в выбранный день.
    private var visibleCategories: [TrackerCategory] = []

    // MARK: UI

    private let datePicker = UIDatePicker()
    private let searchController = UISearchController(searchResultsController: nil)
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private let placeholderImageView = UIImageView()
    private let placeholderLabel = UILabel()

    // MARK: Жизненный цикл

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP White")

        setupNavigationBar()
        setupCollectionView()
        setupPlaceholder()

        reloadVisibleCategories()
    }

    // MARK: Вёрстка кодом

    private func setupNavigationBar() {
        title = "Трекеры"
        navigationController?.navigationBar.prefersLargeTitles = true

        // Кнопка собрана вручную: системный UIBarButtonItem на свежих iOS
        // рисует круглую подложку, а в макете «+» без неё.
        let addButton = UIButton(type: .system)
        addButton.setImage(
            UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .bold)),
            for: .normal
        )
        addButton.tintColor = UIColor(named: "YP Black")
        addButton.accessibilityIdentifier = "add tracker"
        addButton.addTarget(self, action: #selector(didTapAddTracker), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: addButton)

        datePicker.preferredDatePickerStyle = .compact
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.date = currentDate
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)

        // Поле поиска есть в макете главного экрана. Фильтрация — задание
        // следующего спринта, поэтому поле пока не меняет выдачу.
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
        collectionView.accessibilityIdentifier = "trackers collection"
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
        // ⚠️ Картинка-заглушка из Figma («звезда») не подключена — стоит SF Symbol.
        placeholderImageView.image = UIImage(named: "placeholder_star")
            ?? UIImage(systemName: "star.fill")
        placeholderImageView.contentMode = .scaleAspectFit
        placeholderImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(placeholderImageView)

        placeholderLabel.text = "Что будем отслеживать?"
        placeholderLabel.font = .systemFont(ofSize: 12, weight: .medium)
        placeholderLabel.textColor = UIColor(named: "YP Black")
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

    // MARK: Данные

    /// Пересобирает список категорий под выбранный день и обновляет экран.
    private func reloadVisibleCategories() {
        guard let weekDay = WeekDay.from(date: currentDate) else {
            visibleCategories = []
            updateUI()
            return
        }

        visibleCategories = categories.compactMap { category in
            let trackers = category.trackers.filter { $0.schedule.contains(weekDay) }
            return trackers.isEmpty ? nil : TrackerCategory(title: category.title, trackers: trackers)
        }

        updateUI()
    }

    private func updateUI() {
        let isEmpty = visibleCategories.isEmpty
        placeholderImageView.isHidden = !isEmpty
        placeholderLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        collectionView.reloadData()
    }

    /// Новый трекер уходит в категорию по умолчанию.
    /// Массивы не мутируем — собираем новые, как требует задание.
    private func addTracker(_ tracker: Tracker) {
        var updated: [TrackerCategory] = []
        var inserted = false

        for category in categories {
            if category.title == Constants.defaultCategoryTitle {
                updated.append(TrackerCategory(title: category.title, trackers: category.trackers + [tracker]))
                inserted = true
            } else {
                updated.append(category)
            }
        }

        if !inserted {
            updated.append(TrackerCategory(title: Constants.defaultCategoryTitle, trackers: [tracker]))
        }

        categories = updated
        reloadVisibleCategories()
    }

    private func tracker(at indexPath: IndexPath) -> Tracker {
        visibleCategories[indexPath.section].trackers[indexPath.item]
    }

    /// Все отметки трекера за всю историю — это и показывает счётчик.
    private func completedDaysCount(for trackerId: UUID) -> Int {
        completedTrackers.filter { $0.trackerId == trackerId }.count
    }

    private func isCompleted(_ trackerId: UUID, on date: Date) -> Bool {
        completedRecords.contains(TrackerRecord(trackerId: trackerId, date: date.startOfDay))
    }

    // MARK: Действия

    @objc private func didTapAddTracker() {
        // По заданию спринта 14 кнопка «+» сразу открывает создание привычки:
        // экран выбора типа трекера — задание со звёздочкой.
        let newHabit = NewHabitViewController()
        newHabit.onCreate = { [weak self] tracker in
            self?.addTracker(tracker)
        }
        let navigationController = UINavigationController(rootViewController: newHabit)
        present(navigationController, animated: true)
    }

    @objc private func dateChanged() {
        currentDate = datePicker.date
        reloadVisibleCategories()
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
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }

        let tracker = tracker(at: indexPath)
        cell.delegate = self
        cell.configure(
            with: tracker,
            isCompleted: isCompleted(tracker.id, on: currentDate),
            completedDays: completedDaysCount(for: tracker.id),
            isEnabled: currentDate.startOfDay <= Date().startOfDay
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
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        // Две карточки в ряд: ширина делится пополам за вычетом отступов.
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

        // Отметить трекер для будущей даты нельзя.
        guard currentDate.startOfDay <= Date().startOfDay else { return }

        let tracker = tracker(at: indexPath)
        let record = TrackerRecord(trackerId: tracker.id, date: currentDate.startOfDay)

        if completedRecords.contains(record) {
            completedRecords.remove(record)
            completedTrackers.removeAll { $0 == record }
        } else {
            completedRecords.insert(record)
            completedTrackers.append(record)
        }

        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - Date

extension Date {
    /// Полночь этого дня — записи о выполнении сравниваем по дню, не по времени.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
