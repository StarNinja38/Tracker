import CoreData
import UIKit

// MARK: - TrackerStoreDelegate

protocol TrackerStoreDelegate: AnyObject {
    func trackerStoreDidUpdate(_ store: TrackerStore)
}

// MARK: - TrackerStore

/// Слой хранения трекеров. `NSFetchedResultsController` следит за изменениями
/// в Core Data и сообщает о них делегату, а наружу уходят готовые категории
/// с трекерами — экран о Core Data не знает.
final class TrackerStore: NSObject {

    weak var delegate: TrackerStoreDelegate?

    private let context: NSManagedObjectContext

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCoreData> = {
        let request = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.title", ascending: true),
            NSSortDescriptor(keyPath: \TrackerCoreData.createdAt, ascending: true)
        ]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: "category.title",
            cacheName: nil
        )
        controller.delegate = self
        try? controller.performFetch()
        return controller
    }()

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
        super.init()
    }

    /// Трекеры, сгруппированные по категориям, — по одной секции FRC на категорию.
    var categories: [TrackerCategory] {
        (fetchedResultsController.sections ?? []).map { section in
            let trackers = (section.objects as? [TrackerCoreData] ?? []).compactMap(makeTracker)
            return TrackerCategory(title: section.name, trackers: trackers)
        }
    }

    func addTracker(_ tracker: Tracker, toCategoryWithTitle categoryTitle: String) {
        let categoryStore = TrackerCategoryStore(context: context, trackerStore: self)

        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.id = tracker.id
        trackerCoreData.title = tracker.title
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.colorHex = UIColorMarshalling.hexString(from: tracker.color)
        trackerCoreData.schedule = Self.encode(tracker.schedule)
        trackerCoreData.createdAt = Date()
        trackerCoreData.category = categoryStore.categoryCoreData(withTitle: categoryTitle)

        CoreDataStack.shared.saveContext()
    }

    func makeTracker(from trackerCoreData: TrackerCoreData) -> Tracker? {
        guard
            let id = trackerCoreData.id,
            let title = trackerCoreData.title,
            let emoji = trackerCoreData.emoji,
            let colorHex = trackerCoreData.colorHex
        else { return nil }

        return Tracker(
            id: id,
            title: title,
            color: UIColorMarshalling.color(from: colorHex),
            emoji: emoji,
            schedule: Self.decode(trackerCoreData.schedule ?? "")
        )
    }

    // MARK: Расписание

    /// Расписание хранится строкой из номеров дней: `"2,4,6"`.
    /// Пустая строка — нерегулярное событие.
    private static func encode(_ schedule: [WeekDay]) -> String {
        schedule.map { String($0.rawValue) }.joined(separator: ",")
    }

    private static func decode(_ string: String) -> [WeekDay] {
        string.split(separator: ",").compactMap { Int($0).flatMap(WeekDay.init(rawValue:)) }
    }

    /// Объект Core Data для трекера — нужен `TrackerRecordStore`, чтобы связать отметку с трекером.
    func trackerCoreData(with id: UUID) -> TrackerCoreData? {
        fetchedResultsController.fetchedObjects?.first { $0.id == id }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerStore: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerStoreDidUpdate(self)
    }
}
