import Foundation

// MARK: - CategoryCellViewModel

/// Данные одной строки списка категорий.
struct CategoryCellViewModel {
    let title: String
    let isSelected: Bool
}

// MARK: - CategoryListViewModel

/// Вьюмодель экрана «Категория». Берёт категории из `TrackerCategoryStore`,
/// готовит строки для таблицы и обрабатывает выбор. О Core Data не знает.
final class CategoryListViewModel {

    /// Список категорий изменился — таблицу нужно перерисовать.
    var onCategoriesChange: Binding<[CategoryCellViewModel]>?
    /// Текст ошибки чтения или сохранения; `nil` — ошибки нет.
    var onErrorStateChange: Binding<String?>?
    /// Пользователь выбрал категорию — экран создания трекера показывает её под «Категория».
    var onCategorySelected: Binding<String>?

    private(set) var categories: [CategoryCellViewModel] = [] {
        didSet { onCategoriesChange?(categories) }
    }

    var isEmpty: Bool {
        categories.isEmpty
    }

    private let store: TrackerCategoryStore
    private var selectedTitle: String?

    init(store: TrackerCategoryStore = TrackerCategoryStore(), selectedTitle: String?) {
        self.store = store
        self.selectedTitle = selectedTitle
        store.delegate = self
    }

    func loadCategories() {
        do {
            try store.performFetch()
            onErrorStateChange?(nil)
        } catch {
            onErrorStateChange?("Не удалось загрузить категории")
        }
        reloadCategories()
    }

    func didSelectCategory(at index: Int) {
        guard categories.indices.contains(index) else { return }
        let title = categories[index].title
        selectedTitle = title
        reloadCategories()
        onCategorySelected?(title)
    }

    /// Вьюмодель экрана «Новая категория» работает с тем же стором:
    /// новая категория появится в списке по сигналу `NSFetchedResultsController`.
    func makeNewCategoryViewModel() -> CategoryFormViewModel {
        CategoryFormViewModel(mode: .create, store: store)
    }

    private func reloadCategories() {
        categories = store.categoryTitles.map {
            CategoryCellViewModel(title: $0, isSelected: $0 == selectedTitle)
        }
    }
}

// MARK: - TrackerCategoryStoreDelegate

extension CategoryListViewModel: TrackerCategoryStoreDelegate {

    func trackerCategoryStoreDidUpdate(_ store: TrackerCategoryStore) {
        reloadCategories()
    }
}
