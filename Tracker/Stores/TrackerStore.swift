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
    private let fetchedResultsController: NSFetchedResultsController<TrackerCoreData>

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context

        let request = TrackerCoreData.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "category.title", ascending: true),
            NSSortDescriptor(keyPath: \TrackerCoreData.createdAt, ascending: true)
        ]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: "category.title",
            cacheName: nil
        )

        super.init()
        fetchedResultsController.delegate = self
    }

    /// Первое чтение из базы. Ошибка уходит наружу: пустая база и сбой чтения — разные ситуации.
    func performFetch() throws {
        try fetchedResultsController.performFetch()
    }

    /// Трекеры, сгруппированные по категориям, — по одной секции FRC на категорию.
    var categories: [TrackerCategory] {
        (fetchedResultsController.sections ?? []).map { section in
            let trackers = (section.objects as? [TrackerCoreData] ?? []).compactMap(makeTracker)
            return TrackerCategory(title: section.name, trackers: trackers)
        }
    }

    func addTracker(_ tracker: Tracker, toCategoryWithTitle categoryTitle: String) throws {
        let categoryStore = TrackerCategoryStore(context: context, trackerStore: self)
        let category = try categoryStore.categoryCoreData(withTitle: categoryTitle)

        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.id = tracker.id
        trackerCoreData.title = tracker.title
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.colorHex = UIColorMarshalling.hexString(from: tracker.color)
        trackerCoreData.schedule = Self.encode(tracker.schedule)
        trackerCoreData.createdAt = Date()
        trackerCoreData.category = category

        try context.saveOrRollback()
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

    /// Объект Core Data для трекера — нужен `TrackerRecordStore`, чтобы связать отметку с трекером.
    func trackerCoreData(with id: UUID) throws -> TrackerCoreData? {
        let request = TrackerCoreData.fetchRequest()
        // `#keyPath(TrackerCoreData.id)` не собирается: имя `id` пересекается с NSObject.
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
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
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerStore: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerStoreDidUpdate(self)
    }
}
