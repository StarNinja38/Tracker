import CoreData

// MARK: - TrackerCategoryStoreDelegate

protocol TrackerCategoryStoreDelegate: AnyObject {
    func trackerCategoryStoreDidUpdate(_ store: TrackerCategoryStore)
}

// MARK: - TrackerCategoryStore

final class TrackerCategoryStore: NSObject {

    weak var delegate: TrackerCategoryStoreDelegate?

    private let context: NSManagedObjectContext
    private let trackerStore: TrackerStore
    private let fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>

    init(context: NSManagedObjectContext = CoreDataStack.shared.context, trackerStore: TrackerStore = TrackerStore()) {
        self.context = context
        self.trackerStore = trackerStore

        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerCategoryCoreData.title, ascending: true)]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        super.init()
        fetchedResultsController.delegate = self
    }

    func performFetch() throws {
        try fetchedResultsController.performFetch()
    }

    var categories: [TrackerCategory] {
        (fetchedResultsController.fetchedObjects ?? []).map(makeCategory)
    }

    var categoryTitles: [String] {
        (fetchedResultsController.fetchedObjects ?? []).compactMap(\.title)
    }

    func addCategory(title: String) throws {
        let category = TrackerCategoryCoreData(context: context)
        category.title = title
        try context.saveOrRollback()
    }

    func renameCategory(_ title: String, to newTitle: String) throws {
        guard let category = try fetchCategory(withTitle: title) else { return }
        category.title = newTitle
        try context.saveOrRollback()
    }

    // трекеры и записи удалятся вместе с категорией, в модели стоит Cascade
    func deleteCategory(_ title: String) throws {
        guard let category = try fetchCategory(withTitle: title) else { return }
        context.delete(category)
        try context.saveOrRollback()
    }

    // если такой категории нет, создаем новую
    func categoryCoreData(withTitle title: String) throws -> TrackerCategoryCoreData {
        if let existing = try fetchCategory(withTitle: title) {
            return existing
        }
        let category = TrackerCategoryCoreData(context: context)
        category.title = title
        return category
    }

    private func fetchCategory(withTitle title: String) throws -> TrackerCategoryCoreData? {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", #keyPath(TrackerCategoryCoreData.title), title)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func makeCategory(from categoryCoreData: TrackerCategoryCoreData) -> TrackerCategory {
        let trackers = (categoryCoreData.trackers as? Set<TrackerCoreData> ?? [])
            .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
            .compactMap(trackerStore.makeTracker)
        return TrackerCategory(title: categoryCoreData.title ?? "", trackers: trackers)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerCategoryStoreDidUpdate(self)
    }
}
