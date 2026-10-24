import Foundation

// MARK: - TrackerCellViewModel

/// Всё, что нужно карточке трекера на выбранную дату.
struct TrackerCellViewModel {
    let tracker: Tracker
    let isCompleted: Bool
    let completedDays: Int
    let isEnabled: Bool
}

// MARK: - TrackersViewModel

/// Вьюмодель главного экрана: читает трекеры, категории и отметки из сторов,
/// фильтрует их под выбранный день и отмечает выполнение. О Core Data не знает.
final class TrackersViewModel {

    private enum Text {
        static let emptyPlaceholder = "Что будем отслеживать?"
        static let loadError = "Не удалось загрузить трекеры"
    }

    /// Поменялись категории, попадающие в выбранный день, — коллекцию нужно перерисовать.
    var onVisibleCategoriesChange: Binding<[TrackerCategory]>?
    /// Текст заглушки; `nil` — трекеры есть и заглушку нужно спрятать.
    var onPlaceholderChange: Binding<String?>?
    /// Сохранение не удалось — показать алерт.
    var onErrorStateChange: Binding<String>?

    /// Все категории с трекерами — копия того, что лежит в Core Data.
    private(set) var categories: [TrackerCategory] = []

    /// Записи о выполнении. Массив требуется заданием.
    private(set) var completedTrackers: [TrackerRecord] = []

    /// Дата, выбранная в `UIDatePicker`.
    private(set) var currentDate = Date()

    /// Категории, попадающие в выбранный день.
    private(set) var visibleCategories: [TrackerCategory] = []

    /// Дубль записей в `Set` — чтобы проверять выполненность за O(1),
    /// а не линейным поиском по массиву.
    private var completedRecords: Set<TrackerRecord> = []
    private var isLoadFailed = false

    private let trackerStore: TrackerStore
    private let trackerRecordStore: TrackerRecordStore
    private let trackerCategoryStore: TrackerCategoryStore

    init(trackerStore: TrackerStore = TrackerStore()) {
        self.trackerStore = trackerStore
        trackerRecordStore = TrackerRecordStore(trackerStore: trackerStore)
        trackerCategoryStore = TrackerCategoryStore(trackerStore: trackerStore)

        trackerStore.delegate = self
        trackerRecordStore.delegate = self
        trackerCategoryStore.delegate = self
    }

    // MARK: Загрузка

    /// Первое чтение из Core Data. Если база не прочиталась, вместо «Что будем
    /// отслеживать?» пишем об ошибке — иначе сбой выглядел бы как пустой список.
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

    // MARK: Действия

    func didChangeDate(_ date: Date) {
        currentDate = date
        reloadVisibleCategories()
    }

    /// Трекер уходит в выбранную категорию. Экран обновится,
    /// когда `TrackerStore` сообщит об изменении в Core Data.
    func addTracker(_ tracker: Tracker, toCategoryWithTitle categoryTitle: String) {
        do {
            try trackerStore.addTracker(tracker, toCategoryWithTitle: categoryTitle)
        } catch {
            onErrorStateChange?("Не удалось сохранить трекер")
        }
    }

    /// Отмечает трекер выполненным в выбранный день или снимает отметку.
    /// Отметить трекер для будущей даты нельзя.
    func didTapComplete(at indexPath: IndexPath) {
        guard isCurrentDateEditable, let tracker = tracker(at: indexPath) else { return }
        let record = TrackerRecord(trackerId: tracker.id, date: currentDate.startOfDay)

        // Экран перерисуется по сигналу `TrackerRecordStore`.
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

    // MARK: Данные для коллекции

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

    // MARK: Пересборка

    private func reloadCategories() {
        categories = trackerStore.categories
        reloadVisibleCategories()
    }

    private func reloadRecords() {
        completedTrackers = trackerRecordStore.records
        completedRecords = Set(completedTrackers)
        reloadVisibleCategories()
    }

    /// Пересобирает список категорий под выбранный день и сообщает вью.
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

    /// Привычка видна в дни из расписания. Нерегулярное событие к дням не привязано:
    /// пока оно не выполнено, показываем его в любой день, а после выполнения —
    /// только в тот день, когда его отметили.
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

    /// Секции `TrackerStore` построены по названию категории, а переименование
    /// категории сами трекеры не меняет. Поэтому перечитываем трекеры заново.
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
    /// Полночь этого дня — записи о выполнении сравниваем по дню, не по времени.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
