import Foundation

// MARK: - StatisticsItem

struct StatisticsItem {
    let value: Int
    let title: String
}

// MARK: - StatisticsViewModel

final class StatisticsViewModel {

    // nil значит статистики пока нет и нужна заглушка
    var onItemsChange: Binding<[StatisticsItem]?>?

    private let trackerStore: TrackerStore
    private let trackerRecordStore: TrackerRecordStore
    private let calendar = Calendar.current

    init(trackerStore: TrackerStore, trackerRecordStore: TrackerRecordStore) {
        self.trackerStore = trackerStore
        self.trackerRecordStore = trackerRecordStore
        trackerStore.delegate = self
        trackerRecordStore.delegate = self
    }

    convenience init() {
        let trackerStore = TrackerStore()
        self.init(trackerStore: trackerStore, trackerRecordStore: TrackerRecordStore(trackerStore: trackerStore))
    }

    func loadData() {
        do {
            try trackerStore.performFetch()
            try trackerRecordStore.performFetch()
        } catch {
            onItemsChange?(nil)
            return
        }
        recalculate()
    }

    private func recalculate() {
        let records = trackerRecordStore.records
        guard !records.isEmpty else {
            onItemsChange?(nil)
            return
        }
        let trackers = trackerStore.categories.flatMap(\.trackers)
        onItemsChange?([
            StatisticsItem(value: bestPeriod(records), title: NSLocalizedString("statistics.bestPeriod", comment: "")),
            StatisticsItem(value: idealDays(records, trackers: trackers), title: NSLocalizedString("statistics.idealDays", comment: "")),
            StatisticsItem(value: records.count, title: NSLocalizedString("statistics.completed", comment: "")),
            StatisticsItem(value: average(records), title: NSLocalizedString("statistics.average", comment: ""))
        ])
    }

    // самая длинная серия дней подряд, в которые выполнен хотя бы один трекер
    private func bestPeriod(_ records: [TrackerRecord]) -> Int {
        let days = Set(records.map { calendar.startOfDay(for: $0.date) }).sorted()
        var best = 0
        var current = 0
        var previous: Date?
        for day in days {
            if let previous, calendar.dateComponents([.day], from: previous, to: day).day == 1 {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }

    // день идеальный, если выполнены все привычки, запланированные на этот день недели
    private func idealDays(_ records: [TrackerRecord], trackers: [Tracker]) -> Int {
        let recordsByDay = Dictionary(grouping: records) { calendar.startOfDay(for: $0.date) }
        return recordsByDay.filter { day, dayRecords in
            guard let weekDay = WeekDay.from(date: day, calendar: calendar) else { return false }
            let planned = trackers.filter { !$0.isIrregular && $0.schedule.contains(weekDay) }
            guard !planned.isEmpty else { return false }
            let done = Set(dayRecords.map(\.trackerId))
            return planned.allSatisfy { done.contains($0.id) }
        }.count
    }

    // сколько трекеров в среднем выполняется в день, когда было хоть что-то выполнено
    private func average(_ records: [TrackerRecord]) -> Int {
        let daysCount = Set(records.map { calendar.startOfDay(for: $0.date) }).count
        guard daysCount > 0 else { return 0 }
        return Int((Double(records.count) / Double(daysCount)).rounded())
    }
}

// MARK: - TrackerStoreDelegate

extension StatisticsViewModel: TrackerStoreDelegate {

    func trackerStoreDidUpdate(_ store: TrackerStore) {
        recalculate()
    }
}

// MARK: - TrackerRecordStoreDelegate

extension StatisticsViewModel: TrackerRecordStoreDelegate {

    func trackerRecordStoreDidUpdate(_ store: TrackerRecordStore) {
        recalculate()
    }
}
