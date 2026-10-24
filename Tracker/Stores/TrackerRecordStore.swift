import CoreData

// MARK: - TrackerRecordStoreDelegate

protocol TrackerRecordStoreDelegate: AnyObject {
    func trackerRecordStoreDidUpdate(_ store: TrackerRecordStore)
}

// MARK: - TrackerRecordStore

final class TrackerRecordStore: NSObject {

    weak var delegate: TrackerRecordStoreDelegate?

    private let context: NSManagedObjectContext
    private let trackerStore: TrackerStore
    private let fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>

    init(context: NSManagedObjectContext = CoreDataStack.shared.context, trackerStore: TrackerStore) {
        self.context = context
        self.trackerStore = trackerStore

        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrackerRecordCoreData.date, ascending: true)]
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

    var records: [TrackerRecord] {
        (fetchedResultsController.fetchedObjects ?? []).compactMap { recordCoreData in
            guard let trackerId = recordCoreData.trackerId, let date = recordCoreData.date else { return nil }
            return TrackerRecord(trackerId: trackerId, date: date)
        }
    }

    func addRecord(_ record: TrackerRecord) throws {
        let recordCoreData = TrackerRecordCoreData(context: context)
        recordCoreData.trackerId = record.trackerId
        recordCoreData.date = record.date
        recordCoreData.tracker = try trackerStore.trackerCoreData(with: record.trackerId)
        try context.saveOrRollback()
    }

    func removeRecord(_ record: TrackerRecord) throws {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(TrackerRecordCoreData.trackerId), record.trackerId as CVarArg,
            #keyPath(TrackerRecordCoreData.date), record.date as CVarArg
        )
        try context.fetch(request).forEach(context.delete)
        try context.saveOrRollback()
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.trackerRecordStoreDidUpdate(self)
    }
}
