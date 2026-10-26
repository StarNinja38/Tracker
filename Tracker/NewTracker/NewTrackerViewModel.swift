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
            case .category: NSLocalizedString("newTracker.category", comment: "")
            case .schedule: NSLocalizedString("newTracker.schedule", comment: "")
            }
        }
    }

    enum Mode {
        case create
        case edit(tracker: Tracker, categoryTitle: String, completedDays: Int)
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
    let saveButtonTitle: String
    // при редактировании над полем показываем сколько дней уже выполнено
    let completedDaysText: String?
    let initialTitle: String

    private(set) var selectedEmojiIndex: Int?
    private(set) var selectedColorIndex: Int?

    private let type: TrackerType
    private let mode: Mode
    private var title = ""
    private var selectedCategory: String?
    private var selectedSchedule: [WeekDay] = []

    init(type: TrackerType, mode: Mode = .create) {
        self.type = type
        self.mode = mode
        switch type {
        case .habit: options = [.category, .schedule]
        case .irregularEvent: options = [.category]
        }

        switch mode {
        case .create:
            screenTitle = type.screenTitle
            saveButtonTitle = NSLocalizedString("newTracker.create", comment: "")
            completedDaysText = nil
            initialTitle = ""
        case .edit(let tracker, let categoryTitle, let completedDays):
            screenTitle = type.editScreenTitle
            saveButtonTitle = NSLocalizedString("newTracker.save", comment: "")
            completedDaysText = TrackerCell.daysText(completedDays)
            initialTitle = tracker.title
            title = tracker.title
            selectedCategory = categoryTitle
            selectedSchedule = tracker.schedule
            selectedEmojiIndex = emojis.firstIndex(of: tracker.emoji)
            let hex = UIColorMarshalling.hexString(from: tracker.color)
            selectedColorIndex = colors.firstIndex { UIColorMarshalling.hexString(from: UIColor(resource: $0)) == hex }
        }
    }

    convenience init(editing tracker: Tracker, categoryTitle: String, completedDays: Int) {
        self.init(
            type: tracker.isIrregular ? .irregularEvent : .habit,
            mode: .edit(tracker: tracker, categoryTitle: categoryTitle, completedDays: completedDays)
        )
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

        var id = UUID()
        var isPinned = false
        if case .edit(let tracker, _, _) = mode {
            id = tracker.id
            isPinned = tracker.isPinned
        }

        // у нерегулярного события расписание пустое
        let tracker = Tracker(
            id: id,
            title: trimmedTitle,
            color: UIColor(resource: colors[colorIndex]),
            emoji: emojis[emojiIndex],
            schedule: type == .habit ? selectedSchedule : [],
            isPinned: isPinned
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
            if selectedSchedule.count == WeekDay.allCases.count { return NSLocalizedString("newTracker.everyDay", comment: "") }
            return WeekDay.displayOrder
                .filter { selectedSchedule.contains($0) }
                .map(\.shortName)
                .joined(separator: ", ")
        }
    }
}
