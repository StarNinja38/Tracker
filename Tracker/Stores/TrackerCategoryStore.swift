import CoreData

// MARK: - TrackerCategoryStoreDelegate

protocol TrackerCategoryStoreDelegate: AnyObject {
    func trackerCategoryStoreDidUpdate(_ store: TrackerCategoryStore)
}

// MARK: - TrackerCategoryStore

/// Слой хранения категорий. Наружу отдаёт только модели `TrackerCategory`,
/// объекты Core Data остаются внутри слоя.
final class TrackerCategoryStore: NSObject {

    weak var delegate: TrackerCategoryStoreDelegate?

    private let context: NSManagedObjectContext
    private let trackerStore: TrackerStore

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData> = {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerCategoryCoreData.title, ascending: true)]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        try? controller.performFetch()
        return controller
    }()

    init(context: NSManagedObjectContext = CoreDataStack.shared.context, trackerStore: TrackerStore = TrackerStore()) {
        self.context = context
        self.trackerStore = trackerStore
        super.init()
    }

    var categories: [TrackerCategory] {
        (fetchedResultsController.fetchedObjects ?? []).map(makeCategory)
    }

    /// Возвращает категорию с таким названием, а если её нет — создаёт.
    func categoryCoreData(withTitle title: String) -> TrackerCategoryCoreData {
        if let existing = fetchedResultsController.fetchedObjects?.first(where: { $0.title == title }) {
            return existing
        }
        let category = TrackerCategoryCoreData(context: context)
        category.title = title
        return category
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
