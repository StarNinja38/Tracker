import UIKit

// MARK: - NewTrackerOptionViewModel

struct NewTrackerOptionViewModel {
    let title: String
    let subtitle: String?
}

// MARK: - NewTrackerViewModel

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

    var onCreateAllowedStateChange: Binding<Bool>?
    var onOptionsChange: Binding<[NewTrackerOptionViewModel]>?

    // 18 эмодзи и 18 цветов как в фигме
    let emojis = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
    ]
    let colors: [ColorResource] = [
        .colorSelection1, .colorSelection2, .colorSelection3, .colorSelection4, .colorSelection5, .colorSelection6,
        .colorSelection7, .colorSelection8, .colorSelection9, .colorSelection10, .colorSelection11, .colorSelection12,
        .colorSelection13, .colorSelection14, .colorSelection15, .colorSelection16, .colorSelection17, .colorSelection18
    ]

    let screenTitle: String
    let options: [Option]

    private(set) var selectedEmojiIndex: Int?
    private(set) var selectedColorIndex: Int?

    private let type: TrackerType
    private var title = ""
    private var selectedCategory: String?
    private var selectedSchedule: [WeekDay] = []

    init(type: TrackerType) {
        self.type = type
        screenTitle = type.screenTitle
        switch type {
        case .habit: options = [.category, .schedule]
        case .irregularEvent: options = [.category]
        }
    }

    func start() {
        updateCreateAllowedState()
    }

    var optionViewModels: [NewTrackerOptionViewModel] {
        options.map { NewTrackerOptionViewModel(title: $0.title, subtitle: subtitle(for: $0)) }
    }

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
        guard colors.indices.contains(index) else { return }
        selectedColorIndex = index
        updateCreateAllowedState()
    }

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

    func makeTracker() -> (tracker: Tracker, categoryTitle: String)? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard
            isCreateAllowed,
            let emojiIndex = selectedEmojiIndex,
            let colorIndex = selectedColorIndex,
            let categoryTitle = selectedCategory
        else { return nil }

        // у нерегулярного события расписание пустое
        let tracker = Tracker(
            id: UUID(),
            title: trimmedTitle,
            color: UIColor(resource: colors[colorIndex]),
            emoji: emojis[emojiIndex],
            schedule: type == .habit ? selectedSchedule : []
        )
        return (tracker, categoryTitle)
    }

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
