import CoreData

// MARK: - CoreDataStack

/// Единственный `NSPersistentContainer` приложения. Им пользуются все три
/// `Store`, поэтому `import CoreData` за пределами слоя хранения не нужен.
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

    /// Сохраняет изменения, а при ошибке откатывает их и отдаёт ошибку вызывающему.
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
