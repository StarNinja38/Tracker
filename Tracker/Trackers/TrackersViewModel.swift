import Foundation

// MARK: - TrackerCellViewModel

struct TrackerCellViewModel {
    let tracker: Tracker
    let isCompleted: Bool
    let completedDays: Int
    let isEnabled: Bool
}

// MARK: - TrackersViewModel

final class TrackersViewModel {

    private enum Text {
        static let emptyPlaceholder = "Что будем отслеживать?"
        static let loadError = "Не удалось загрузить трекеры"
    }

    var onVisibleCategoriesChange: Binding<[TrackerCategory]>?
    var onPlaceholderChange: Binding<String?>?
    var onErrorStateChange: Binding<String>?

    private(set) var categories: [TrackerCategory] = []

    // массив нужен по заданию
    private(set) var completedTrackers: [TrackerRecord] = []

    private(set) var currentDate: Date

    private(set) var visibleCategories: [TrackerCategory] = []

    // в Set чтобы быстро проверять, выполнен ли трекер
    private var completedRecords: Set<TrackerRecord> = []
    private var isLoadFailed = false

    private let trackerStore: TrackerStore
    private let trackerRecordStore: TrackerRecordStore
    private let trackerCategoryStore: TrackerCategoryStore

    init(
        trackerStore: TrackerStore,
        trackerRecordStore: TrackerRecordStore,
        trackerCategoryStore: TrackerCategoryStore,
        currentDate: Date = Date()
    ) {
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

    func didChangeDate(_ date: Date) {
        currentDate = date
        reloadVisibleCategories()
    }

    func addTracker(_ tracker: Tracker, toCategoryWithTitle categoryTitle: String) {
        do {
            try trackerStore.addTracker(tracker, toCategoryWithTitle: categoryTitle)
        } catch {
            onErrorStateChange?("Не удалось сохранить трекер")
        }
    }

    // на будущую дату отмечать нельзя
    func didTapComplete(at indexPath: IndexPath) {
        guard isCurrentDateEditable, let tracker = tracker(at: indexPath) else { return }
        let record = TrackerRecord(trackerId: tracker.id, date: currentDate.startOfDay)

        do {
            if completedRecords.contains(record) {
                try trackerRecordStore.removeRecord(record)
            } else {
                try trackerRecordStore.addRecord(record)
            }
        } catch {
            onErrorStateChange?("Не удалось сохранить отметку")
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
        if let weekDay = WeekDay.from(date: currentDate) {
            visibleCategories = categories.compactMap { category in
                let trackers = category.trackers.filter { isVisible($0, weekDay: weekDay) }
                return trackers.isEmpty ? nil : TrackerCategory(title: category.title, trackers: trackers)
            }
        } else {
            visibleCategories = []
        }

        onVisibleCategoriesChange?(visibleCategories)
        let placeholder = isLoadFailed ? Text.loadError : Text.emptyPlaceholder
        onPlaceholderChange?(visibleCategories.isEmpty ? placeholder : nil)
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
            onErrorStateChange?("Не удалось обновить трекеры")
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
