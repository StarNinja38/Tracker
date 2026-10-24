import UIKit

// MARK: - NewTrackerOptionViewModel

/// Строка-кнопка под полем названия: «Категория» или «Расписание»
/// и выбранное значение вторичным текстом.
struct NewTrackerOptionViewModel {
    let title: String
    let subtitle: String?
}

// MARK: - NewTrackerViewModel

/// Вьюмодель создания привычки или нерегулярного события: хранит всё,
/// что выбрал пользователь, решает, доступна ли «Создать», и собирает `Tracker`.
final class NewTrackerViewModel {

    enum Option {
        case category
        case schedule

        var title: String {
            switch self {
            case .category: return "Категория"
            case .schedule: return "Расписание"
            }
        }
    }

    private enum Constants {
        static let titleLimit = 38
    }

    /// «Создать» доступна, когда заполнены все разделы.
    var onCreateAllowedStateChange: Binding<Bool>?
    /// Поменялась категория или расписание — нужно перерисовать строки под полем.
    var onOptionsChange: Binding<[NewTrackerOptionViewModel]>?

    /// 18 эмодзи и 18 цветов из макета Figma.
    let emojis = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
    ]
    let colorNames = (1...18).map { "Color selection \($0)" }

    let screenTitle: String
    let options: [Option]

    private(set) var selectedEmojiIndex: Int?
    private(set) var selectedColorIndex: Int?

    private let type: TrackerType
    private var title = ""
    private var selectedCategory: String?
    private var selectedSchedule: [WeekDay] = []

    /// У нерегулярного события нет раздела «Расписание», в остальном экраны одинаковые.
    init(type: TrackerType) {
        self.type = type
        screenTitle = type.screenTitle
        switch type {
        case .habit: options = [.category, .schedule]
        case .irregularEvent: options = [.category]
        }
    }

    /// Вызывается из `bind()`, чтобы вью сразу получила начальное состояние.
    func start() {
        updateCreateAllowedState()
    }

    var optionViewModels: [NewTrackerOptionViewModel] {
        options.map { NewTrackerOptionViewModel(title: $0.title, subtitle: subtitle(for: $0)) }
    }

    // MARK: Ввод

    /// Не даёт ввести больше 38 символов.
    func canChangeTitle(to text: String) -> Bool {
        text.count <= Constants.titleLimit
    }

    func didChangeTitle(_ text: String) {
        title = text
        updateCreateAllowedState()
    }

    func didSelectEmoji(at index: Int) {
        guard emojis.indices.contains(index) else { return }
        selectedEmojiIndex = index
        updateCreateAllowedState()
    }

    func didSelectColor(at index: Int) {
        guard colorNames.indices.contains(index) else { return }
        selectedColorIndex = index
        updateCreateAllowedState()
    }

    // MARK: Вложенные экраны

    func makeCategoryListViewModel() -> CategoryListViewModel {
        let viewModel = CategoryListViewModel(selectedTitle: selectedCategory)
        viewModel.onSelectionChange = { [weak self] title in
            self?.selectedCategory = title
            self?.optionsDidChange()
        }
        return viewModel
    }

    func makeScheduleViewModel() -> ScheduleViewModel {
        let viewModel = ScheduleViewModel(selectedDays: selectedSchedule)
        viewModel.onDone = { [weak self] days in
            self?.selectedSchedule = days
            self?.optionsDidChange()
        }
        return viewModel
    }

    // MARK: Создание

    /// Готовый трекер и его категория; `nil`, если заполнено не всё.
    func makeTracker() -> (tracker: Tracker, categoryTitle: String)? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard
            isCreateAllowed,
            let emojiIndex = selectedEmojiIndex,
            let colorIndex = selectedColorIndex,
            let color = UIColor(named: colorNames[colorIndex]),
            let categoryTitle = selectedCategory
        else { return nil }

        // Пустое расписание — признак нерегулярного события.
        let tracker = Tracker(
            id: UUID(),
            title: trimmedTitle,
            color: color,
            emoji: emojis[emojiIndex],
            schedule: type == .habit ? selectedSchedule : []
        )
        return (tracker, categoryTitle)
    }

    // MARK: Состояние

    /// Название, категория, эмодзи, цвет и — только у привычки — хотя бы один день расписания.
    private var isCreateAllowed: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespaces).isEmpty
        let hasSchedule = type == .irregularEvent || !selectedSchedule.isEmpty
        return hasTitle && selectedCategory != nil && hasSchedule
            && selectedEmojiIndex != nil && selectedColorIndex != nil
    }

    private func updateCreateAllowedState() {
        onCreateAllowedStateChange?(isCreateAllowed)
    }

    private func optionsDidChange() {
        onOptionsChange?(optionViewModels)
        updateCreateAllowedState()
    }

    private func subtitle(for option: Option) -> String? {
        switch option {
        case .category:
            return selectedCategory
        case .schedule:
            guard !selectedSchedule.isEmpty else { return nil }
            if selectedSchedule.count == WeekDay.allCases.count { return "Каждый день" }
            return WeekDay.displayOrder
                .filter { selectedSchedule.contains($0) }
                .map(\.shortName)
                .joined(separator: ", ")
        }
    }
}
