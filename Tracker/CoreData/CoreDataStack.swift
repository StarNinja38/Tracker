import CoreData

// MARK: - CoreDataStack

// один контейнер на все сторы
final class CoreDataStack {

    static let shared = CoreDataStack()

    private let modelName = "Tracker"

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Не удалось загрузить хранилище Core Data: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init() {}
}

// MARK: - NSManagedObjectContext

extension NSManagedObjectContext {

    func saveOrRollback() throws {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}
