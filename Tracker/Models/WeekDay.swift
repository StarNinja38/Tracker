import Foundation

// MARK: - WeekDay

/// Дни недели для расписания привычки.
/// `rawValue` совпадает с номером дня в `Calendar` (1 — воскресенье), чтобы
/// сопоставление с датой из `UIDatePicker` было прямым, без таблиц перевода.
enum WeekDay: Int, CaseIterable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    /// Порядок отображения — с понедельника, как в макете.
    static let displayOrder: [WeekDay] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var fullName: String {
        switch self {
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }

    var shortName: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Вс"
        }
    }

    /// День недели, на который приходится дата.
    static func from(date: Date, calendar: Calendar = .current) -> WeekDay? {
        WeekDay(rawValue: calendar.component(.weekday, from: date))
    }
}
