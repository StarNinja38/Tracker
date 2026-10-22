import CoreData

// MARK: - TrackerRecordStoreDelegate

protocol TrackerRecordStoreDelegate: AnyObject {
    func trackerRecordStoreDidUpdate(_ store: TrackerRecordStore)
}

// MARK: - TrackerRecordStore

/// Слой хранения отметок о выполнении.
final class TrackerRecordStore: NSObject {

    weak var delegate: TrackerRecordStoreDelegate?

    private let context: NSManagedObjectContext
    private let trackerStore: TrackerStore

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData> = {
        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerRecordCoreData.date, ascending: true)]
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

    init(context: NSManagedObjectContext = CoreDataStack.shared.context, trackerStore: TrackerStore) {
        self.context = context
        self.trackerStore = trackerStore
        super.init()
    }

    var records: [TrackerRecord] {
        (fetchedResultsController.fetchedObjects ?? []).compactMap { recordCoreData in
            guard let trackerId = recordCoreData.trackerId, let date = recordCoreData.date else { return nil }
            return TrackerRecord(trackerId: trackerId, date: date)
        }
    }

    func addRecord(_ record: TrackerRecord) {
        let recordCoreData = TrackerRecordCoreData(context: context)
        recordCoreData.trackerId = record.trackerId
        recordCoreData.date = record.date
        recordCoreData.tracker = trackerStore.trackerCoreData(with: record.trackerId)
        CoreDataStack.shared.saveContext()
    }

    func removeRecord(_ record: TrackerRecord) {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(TrackerRecordCoreData.trackerId), record.trackerId as CVarArg,
            #keyPath(TrackerRecordCoreData.date), record.date as CVarArg
        )
        let matches = (try? context.fetch(request)) ?? []
        matches.forEach(context.delete)
        CoreDataStack.shared.saveContext()
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerRecordStoreDidUpdate(self)
    }
}
