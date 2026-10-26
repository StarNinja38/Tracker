import Foundation

// MARK: - TrackerCellViewModel

struct TrackerCellViewModel {
    let tracker: Tracker
    let isCompleted: Bool
    let completedDays: Int
    let isEnabled: Bool
}

// MARK: - TrackersPlaceholder

enum TrackersPlaceholder {
    case empty
    case nothingFound
    case loadError

    var text: String {
        switch self {
        case .empty: NSLocalizedString("main.empty", comment: "")
        case .nothingFound: NSLocalizedString("main.nothingFound", comment: "")
        case .loadError: NSLocalizedString("main.loadError", comment: "")
        }
    }
}

// MARK: - FilterButtonState

struct FilterButtonState {
    let isHidden: Bool
    let isActive: Bool
}

// MARK: - TrackersViewModel

final class TrackersViewModel {

    private enum Text {
        static let pinned = NSLocalizedString("main.pinned", comment: "")
        static let pin = NSLocalizedString("menu.pin", comment: "")
        static let unpin = NSLocalizedString("menu.unpin", comment: "")
    }

    var onVisibleCategoriesChange: Binding<[TrackerCategory]>?
    var onPlaceholderChange: Binding<TrackersPlaceholder?>?
    var onFilterButtonChange: Binding<FilterButtonState>?
    // фильтр трекеров на сегодня сам переключает дату в календаре
    var onDateChange: Binding<Date>?
    var onErrorStateChange: Binding<String>?

    private(set) var categories: [TrackerCategory] = []

    // массив нужен по заданию
    private(set) var completedTrackers: [TrackerRecord] = []

    private(set) var currentDate: Date

    private(set) var visibleCategories: [TrackerCategory] = []
    private(set) var currentFilter: TrackerFilter = .all
    private var searchText = ""

    // в Set чтобы быстро проверять, выполнен ли трекер
    private var completedRecords: Set<TrackerRecord> = []
    private var isLoadFailed = false

    private let trackerStore: TrackerStore
    private let trackerRecordStore: TrackerRecordStore
    private let trackerCategoryStore: TrackerCategoryStore
    private let analytics: AnalyticsServiceProtocol

    init(
        trackerStore: TrackerStore,
        trackerRecordStore: TrackerRecordStore,
        trackerCategoryStore: TrackerCategoryStore,
        currentDate: Date = Date(),
        analytics: AnalyticsServiceProtocol = AnalyticsService()
    ) {
        self.analytics = analytics
        self.trackerStore = trackerStore
        self.trackerRecordStore = trackerRecordStore
        self.trackerCategoryStore = trackerCategoryStore
        self.currentDate = currentDate

        trackerStore.delegate = self
        trackerRecordStore.delegate = self
        trackerCategoryStore.delegate = self
    }

    convenience init() {
        let trackerStore = TrackerStore()
        self.init(
            trackerStore: trackerStore,
            trackerRecordStore: TrackerRecordStore(trackerStore: trackerStore),
            trackerCategoryStore: TrackerCategoryStore(trackerStore: trackerStore)
        )
    }

    // если база не загрузилась, показываю ошибку, а не пустую заглушку
    func loadData() {
        do {
            try trackerStore.performFetch()
            try trackerRecordStore.performFetch()
            try trackerCategoryStore.performFetch()
            isLoadFailed = false
        } catch {
            isLoadFailed = true
        }
        reloadCategories()
        reloadRecords()
    }

    // MARK: - Аналитика

    func viewDidAppear() {
        analytics.report(event: .open, screen: .main, item: nil)
    }

    func viewDidDisappear() {
        analytics.report(event: .close, screen: .main, item: nil)
    }

    func didTapAddTracker() {
        analytics.report(event: .click, screen: .main, item: .addTrack)
    }

    func didTapFilters() {
        analytics.report(event: .click, screen: .main, item: .filter)
    }

    func didSelectEdit() {
        analytics.report(event: .click, screen: .main, item: .edit)
    }

    func didSelectDelete() {
        analytics.report(event: .click, screen: .main, item: .delete)
    }

    func didChangeDate(_ date: Date) {
        currentDate = date
        reloadVisibleCategories()
    }

    func didChangeSearchText(_ text: String) {
        searchText = text.trimmingCharacters(in: .whitespaces)
        reloadVisibleCategories()
    }

    func makeFiltersViewModel() -> FiltersViewModel {
        let viewModel = FiltersViewModel(selectedFilter: currentFilter)
        viewModel.onFilterSelected = { [weak self] filter in
            self?.didSelectFilter(filter)
        }
        return viewModel
    }

    private func didSelectFilter(_ filter: TrackerFilter) {
        if filter == .today {
            currentDate = Date()
            onDateChange?(currentDate)
            currentFilter = .all
        } else {
            currentFilter = filter
        }
        reloadVisibleCategories()
    }

    func addTracker(_ tracker: Tracker, toCategoryWithTitle categoryTitle: String) {
        do {
            try trackerStore.addTracker(tracker, toCategoryWithTitle: categoryTitle)
        } catch {
            onErrorStateChange?(NSLocalizedString("error.saveTracker", comment: ""))
        }
    }

    func updateTracker(_ tracker: Tracker, categoryTitle: String) {
        do {
            try trackerStore.updateTracker(tracker, categoryTitle: categoryTitle)
        } catch {
            onErrorStateChange?(NSLocalizedString("error.saveTracker", comment: ""))
        }
    }

    // MARK: - Контекстное меню

    func trackerId(at indexPath: IndexPath) -> UUID? {
        tracker(at: indexPath)?.id
    }

    func pinActionTitle(at indexPath: IndexPath) -> String {
        tracker(at: indexPath)?.isPinned == true ? Text.unpin : Text.pin
    }

    func didTogglePin(at indexPath: IndexPath) {
        guard let tracker = tracker(at: indexPath) else { return }
        do {
            try trackerStore.setPinned(!tracker.isPinned, forTrackerWith: tracker.id)
        } catch {
            onErrorStateChange?(NSLocalizedString("error.pinTracker", comment: ""))
        }
    }

    func deleteTracker(id: UUID) {
        do {
            try trackerStore.deleteTracker(id: id)
        } catch {
            onErrorStateChange?(NSLocalizedString("error.deleteTracker", comment: ""))
        }
    }

    func makeEditViewModel(at indexPath: IndexPath) -> NewTrackerViewModel? {
        guard
            let tracker = tracker(at: indexPath),
            let categoryTitle = categories.first(where: { $0.trackers.contains { $0.id == tracker.id } })?.title
        else { return nil }
        return NewTrackerViewModel(
            editing: tracker,
            categoryTitle: categoryTitle,
            completedDays: completedTrackers.filter { $0.trackerId == tracker.id }.count
        )
    }

    // на будущую дату отмечать нельзя
    func didTapComplete(at indexPath: IndexPath) {
        analytics.report(event: .click, screen: .main, item: .track)
        guard isCurrentDateEditable, let tracker = tracker(at: indexPath) else { return }
        let record = TrackerRecord(trackerId: tracker.id, date: currentDate.startOfDay)

        do {
            if completedRecords.contains(record) {
                try trackerRecordStore.removeRecord(record)
            } else {
                try trackerRecordStore.addRecord(record)
            }
        } catch {
            onErrorStateChange?(NSLocalizedString("error.saveRecord", comment: ""))
        }
    }

    func cellViewModel(at indexPath: IndexPath) -> TrackerCellViewModel? {
        guard let tracker = tracker(at: indexPath) else { return nil }
        return TrackerCellViewModel(
            tracker: tracker,
            isCompleted: completedRecords.contains(TrackerRecord(trackerId: tracker.id, date: currentDate.startOfDay)),
            completedDays: completedTrackers.filter { $0.trackerId == tracker.id }.count,
            isEnabled: isCurrentDateEditable
        )
    }

    private var isCurrentDateEditable: Bool {
        currentDate.startOfDay <= Date().startOfDay
    }

    private func tracker(at indexPath: IndexPath) -> Tracker? {
        guard
            visibleCategories.indices.contains(indexPath.section),
            visibleCategories[indexPath.section].trackers.indices.contains(indexPath.item)
        else { return nil }
        return visibleCategories[indexPath.section].trackers[indexPath.item]
    }

    private func reloadCategories() {
        categories = trackerStore.categories
        reloadVisibleCategories()
    }

    private func reloadRecords() {
        completedTrackers = trackerRecordStore.records
        completedRecords = Set(completedTrackers)
        reloadVisibleCategories()
    }

    private func reloadVisibleCategories() {
        guard let weekDay = WeekDay.from(date: currentDate) else { return }
        let dayTrackers = categories.flatMap(\.trackers).filter { isVisible($0, weekDay: weekDay) }
        let shownIds = Set(dayTrackers.filter(matchesFilterAndSearch).map(\.id))

        // закрепленные трекеры уходят из своей категории в отдельную секцию сверху
        let pinned = dayTrackers.filter { $0.isPinned && shownIds.contains($0.id) }
        let others: [TrackerCategory] = categories.compactMap { category in
            let trackers = category.trackers.filter { !$0.isPinned && shownIds.contains($0.id) }
            return trackers.isEmpty ? nil : TrackerCategory(title: category.title, trackers: trackers)
        }
        visibleCategories = pinned.isEmpty ? others : [TrackerCategory(title: Text.pinned, trackers: pinned)] + others
        onVisibleCategoriesChange?(visibleCategories)

        // кнопку фильтров прячем, если на этот день трекеров нет совсем
        onFilterButtonChange?(FilterButtonState(isHidden: dayTrackers.isEmpty, isActive: currentFilter.isActive))

        if dayTrackers.isEmpty {
            onPlaceholderChange?(isLoadFailed ? .loadError : .empty)
        } else {
            onPlaceholderChange?(visibleCategories.isEmpty ? .nothingFound : nil)
        }
    }

    private func matchesFilterAndSearch(_ tracker: Tracker) -> Bool {
        if !searchText.isEmpty && !tracker.title.localizedCaseInsensitiveContains(searchText) {
            return false
        }
        let isCompleted = completedRecords.contains(TrackerRecord(trackerId: tracker.id, date: currentDate.startOfDay))
        switch currentFilter {
        case .all, .today: return true
        case .completed: return isCompleted
        case .uncompleted: return !isCompleted
        }
    }

    // нерегулярное событие видно каждый день, пока не выполнено, потом только в день выполнения
    private func isVisible(_ tracker: Tracker, weekDay: WeekDay) -> Bool {
        guard tracker.isIrregular else {
            return tracker.schedule.contains(weekDay)
        }
        let completedDates = completedTrackers
            .filter { $0.trackerId == tracker.id }
            .map(\.date)
        return completedDates.isEmpty || completedDates.contains(currentDate.startOfDay)
    }
}

// MARK: - TrackerStoreDelegate

extension TrackersViewModel: TrackerStoreDelegate {

    func trackerStoreDidUpdate(_ store: TrackerStore) {
        reloadCategories()
    }
}

// MARK: - TrackerRecordStoreDelegate

extension TrackersViewModel: TrackerRecordStoreDelegate {

    func trackerRecordStoreDidUpdate(_ store: TrackerRecordStore) {
        reloadRecords()
    }
}

// MARK: - TrackerCategoryStoreDelegate

extension TrackersViewModel: TrackerCategoryStoreDelegate {

    // после переименования категории FRC трекеров сам не обновится, поэтому перезапрашиваю
    func trackerCategoryStoreDidUpdate(_ store: TrackerCategoryStore) {
        do {
            try trackerStore.performFetch()
        } catch {
            onErrorStateChange?(NSLocalizedString("error.updateTrackers", comment: ""))
        }
        reloadCategories()
    }
}

// MARK: - Date

extension Date {
    // записи сравниваю только по дню, без времени
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
