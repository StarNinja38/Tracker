import Foundation

// MARK: - CategoryCellViewModel

struct CategoryCellViewModel {
    let title: String
    let isSelected: Bool
}

// MARK: - CategoryListViewModel

final class CategoryListViewModel {

    var onCategoriesChange: Binding<[CategoryCellViewModel]>?
    var onErrorStateChange: Binding<String?>?
    var onSelectionChange: Binding<String?>?

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
            onErrorStateChange?(NSLocalizedString("error.loadCategories", comment: ""))
        }
        reloadCategories()
    }

    func didSelectCategory(at index: Int) {
        guard categories.indices.contains(index) else { return }
        let title = categories[index].title
        selectedTitle = title
        reloadCategories()
        onSelectionChange?(title)
    }

    func deleteCategory(at index: Int) {
        guard categories.indices.contains(index) else { return }
        let title = categories[index].title
        do {
            try store.deleteCategory(title)
        } catch {
            onErrorStateChange?(NSLocalizedString("error.deleteCategory", comment: ""))
            return
        }
        if title == selectedTitle {
            selectedTitle = nil
            onSelectionChange?(nil)
        }
    }

    func makeNewCategoryViewModel() -> CategoryFormViewModel {
        CategoryFormViewModel(mode: .create, store: store)
    }

    func makeEditCategoryViewModel(at index: Int) -> CategoryFormViewModel? {
        guard categories.indices.contains(index) else { return nil }
        let viewModel = CategoryFormViewModel(mode: .edit(title: categories[index].title), store: store)
        viewModel.onCategoryRename = { [weak self] rename in
            guard let self, rename.old == self.selectedTitle else { return }
            self.selectedTitle = rename.new
            self.reloadCategories()
            self.onSelectionChange?(rename.new)
        }
        return viewModel
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
