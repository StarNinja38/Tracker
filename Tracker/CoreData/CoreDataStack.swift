import CoreData

// MARK: - CoreDataStack

// один контейнер на все сторы
final class CoreDataStack {

    static let shared = CoreDataStack()

    // модель грузим один раз, иначе при втором контейнере (в тестах) Core Data путает классы сущностей
    private static let model: NSManagedObjectModel = {
        guard
            let url = Bundle.main.url(forResource: "Tracker", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: url)
        else {
            return NSManagedObjectModel()
        }
        return model
    }()

    private let modelName = "Tracker"
    private let inMemory: Bool

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: Self.model)
        // для тестов база в памяти, чтобы не трогать настоящие данные
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
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

    init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }
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
