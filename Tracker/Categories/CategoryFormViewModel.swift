import Foundation

// MARK: - CategoryFormViewModel

final class CategoryFormViewModel {

    enum Mode {
        case create
        case edit(title: String)
    }

    private enum Constants {
        static let titleLimit = 38
    }

    var onDoneAllowedStateChange: Binding<Bool>?
    var onErrorStateChange: Binding<String?>?
    var onFinish: (() -> Void)?
    var onCategoryRename: Binding<(old: String, new: String)>?

    let screenTitle: String
    let initialText: String
    let placeholder = "Введите название категории"

    private let mode: Mode
    private let store: TrackerCategoryStore
    private var title = ""

    init(mode: Mode, store: TrackerCategoryStore) {
        self.mode = mode
        self.store = store

        switch mode {
        case .create:
            screenTitle = "Новая категория"
            initialText = ""
        case .edit(let title):
            screenTitle = "Редактирование категории"
            initialText = title
        }
        title = initialText
    }

    func start() {
        validate()
    }

    func canChangeTitle(to text: String) -> Bool {
        text.count <= Constants.titleLimit
    }

    func didChangeTitle(_ text: String) {
        title = text
        validate()
    }

    func didTapDone() {
        let trimmed = trimmedTitle
        guard isValid(trimmed) else { return }
        do {
            switch mode {
            case .create:
                try store.addCategory(title: trimmed)
            case .edit(let oldTitle):
                if trimmed != oldTitle {
                    try store.renameCategory(oldTitle, to: trimmed)
                    onCategoryRename?((old: oldTitle, new: trimmed))
                }
            }
            onFinish?()
        } catch {
            onErrorStateChange?("Не удалось сохранить категорию")
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespaces)
    }

    private func validate() {
        let trimmed = trimmedTitle
        onErrorStateChange?(isDuplicate(trimmed) ? "Такая категория уже есть" : nil)
        onDoneAllowedStateChange?(isValid(trimmed))
    }

    private func isValid(_ title: String) -> Bool {
        !title.isEmpty && !isDuplicate(title)
    }

    // при редактировании старое название дублем не считается
    private func isDuplicate(_ title: String) -> Bool {
        if case .edit(let oldTitle) = mode, title == oldTitle { return false }
        return store.categoryTitles.contains(title)
    }
}
