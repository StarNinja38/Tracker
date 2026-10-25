import SnapshotTesting
import XCTest
@testable import Tracker

final class TrackersViewControllerSnapshotTests: XCTestCase {

    // фиксированная дата, иначе снимок менялся бы каждый день
    private let date = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 12)) ?? Date()

    func testEmptyMainScreen() {
        assertMainScreenSnapshot(withTrackers: false, style: .light)
    }

    func testMainScreenWithTrackers() {
        assertMainScreenSnapshot(withTrackers: true, style: .light)
    }

    func testEmptyMainScreenDark() {
        assertMainScreenSnapshot(withTrackers: false, style: .dark)
    }

    func testMainScreenWithTrackersDark() {
        assertMainScreenSnapshot(withTrackers: true, style: .dark)
    }

    // снимаю окно целиком: обычный снимок контроллера не рисует кнопки в навбаре
    private func assertMainScreenSnapshot(
        withTrackers: Bool,
        style: UIUserInterfaceStyle,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        let window = makeWindow()
        let viewController = makeMainScreen(withTrackers: withTrackers)
        viewController.overrideUserInterfaceStyle = style
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))

        assertSnapshot(
            of: viewController.view,
            as: .image(drawHierarchyInKeyWindow: true),
            file: file,
            testName: testName,
            line: line
        )
    }

    private func makeWindow() -> UIWindow {
        let frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return UIWindow(frame: frame)
        }
        let window = UIWindow(windowScene: scene)
        window.frame = frame
        return window
    }

    private func makeMainScreen(withTrackers: Bool) -> UIViewController {
        let stack = CoreDataStack(inMemory: true)
        let trackerStore = TrackerStore(context: stack.context)
        let recordStore = TrackerRecordStore(context: stack.context, trackerStore: trackerStore)
        let categoryStore = TrackerCategoryStore(context: stack.context, trackerStore: trackerStore)

        if withTrackers {
            let run = Tracker(id: UUID(), title: "Бег по утрам", color: .systemRed, emoji: "🏓", schedule: WeekDay.allCases)
            let read = Tracker(id: UUID(), title: "Читать книгу", color: .systemGreen, emoji: "🥦", schedule: WeekDay.allCases)
            try? trackerStore.addTracker(run, toCategoryWithTitle: "Спорт")
            try? trackerStore.addTracker(read, toCategoryWithTitle: "Учёба")
            try? recordStore.addRecord(TrackerRecord(trackerId: run.id, date: date.startOfDay))
        }

        let viewModel = TrackersViewModel(
            trackerStore: trackerStore,
            trackerRecordStore: recordStore,
            trackerCategoryStore: categoryStore,
            currentDate: date
        )
        return UINavigationController(rootViewController: TrackersViewController(viewModel: viewModel))
    }
}
