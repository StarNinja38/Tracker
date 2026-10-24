import CoreData
import UIKit

// MARK: - TrackerStoreDelegate

protocol TrackerStoreDelegate: AnyObject {
    func trackerStoreDidUpdate(_ store: TrackerStore)
}

// MARK: - TrackerStore

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

    func performFetch() throws {
        try fetchedResultsController.performFetch()
    }

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

    func trackerCoreData(with id: UUID) throws -> TrackerCoreData? {
        let request = TrackerCoreData.fetchRequest()
        // через #keyPath не собирается, id конфликтует с NSObject
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // расписание храню строкой с номерами дней, например "2,4,6", пустая строка значит нерегулярное событие
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
