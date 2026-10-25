import XCTest
@testable import Tracker

final class StatisticsViewModelTests: XCTestCase {

    private let calendar = Calendar.current

    func testEmptyStatisticsShowsPlaceholder() {
        let (viewModel, _, _) = makeViewModel()
        var result: [StatisticsItem]? = []
        viewModel.onItemsChange = { result = $0 }

        viewModel.loadData()

        XCTAssertNil(result)
    }

    func testStatisticsValues() throws {
        let (viewModel, trackerStore, recordStore) = makeViewModel()
        let run = Tracker(id: UUID(), title: "Бег", color: .red, emoji: "🏓", schedule: WeekDay.allCases)
        let read = Tracker(id: UUID(), title: "Чтение", color: .green, emoji: "🥦", schedule: WeekDay.allCases)
        try trackerStore.addTracker(run, toCategoryWithTitle: "Спорт")
        try trackerStore.addTracker(read, toCategoryWithTitle: "Учёба")

        // 3 дня подряд бег, в первый день еще и чтение, потом пропуск и снова бег
        let start = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_760_000_000))
        for offset in [0, 1, 2, 4] {
            let day = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            try recordStore.addRecord(TrackerRecord(trackerId: run.id, date: day))
        }
        try recordStore.addRecord(TrackerRecord(trackerId: read.id, date: start))

        var result: [StatisticsItem]?
        viewModel.onItemsChange = { result = $0 }
        viewModel.loadData()

        let values = try XCTUnwrap(result).map(\.value)
        XCTAssertEqual(values, [3, 1, 5, 1]) // лучший период, идеальные дни, завершено, среднее
    }

    private func makeViewModel() -> (StatisticsViewModel, TrackerStore, TrackerRecordStore) {
        let stack = CoreDataStack(inMemory: true)
        let trackerStore = TrackerStore(context: stack.context)
        let recordStore = TrackerRecordStore(context: stack.context, trackerStore: trackerStore)
        let viewModel = StatisticsViewModel(trackerStore: trackerStore, trackerRecordStore: recordStore)
        return (viewModel, trackerStore, recordStore)
    }
}
