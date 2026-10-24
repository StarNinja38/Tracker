import Foundation

// MARK: - ScheduleViewModel

/// Вьюмодель экрана «Расписание»: какие дни включены и что вернуть по «Готово».
final class ScheduleViewModel {

    /// Пользователь нажал «Готово» — выбранные дни уходят на экран создания привычки.
    var onDone: Binding<[WeekDay]>?

    let days = WeekDay.displayOrder

    private var selectedDays: [WeekDay]

    init(selectedDays: [WeekDay]) {
        self.selectedDays = selectedDays
    }

    func isSelected(_ day: WeekDay) -> Bool {
        selectedDays.contains(day)
    }

    func setDay(_ day: WeekDay, isOn: Bool) {
        if isOn {
            guard !selectedDays.contains(day) else { return }
            selectedDays.append(day)
        } else {
            selectedDays.removeAll { $0 == day }
        }
    }

    func didTapDone() {
        onDone?(selectedDays)
    }
}
