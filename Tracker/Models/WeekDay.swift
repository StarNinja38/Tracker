import Foundation

// MARK: - WeekDay

// rawValue как в Calendar, 1 это воскресенье
enum WeekDay: Int, CaseIterable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    // в макете неделя начинается с понедельника
    static let displayOrder: [WeekDay] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var fullName: String {
        switch self {
        case .monday: NSLocalizedString("weekday.monday", comment: "")
        case .tuesday: NSLocalizedString("weekday.tuesday", comment: "")
        case .wednesday: NSLocalizedString("weekday.wednesday", comment: "")
        case .thursday: NSLocalizedString("weekday.thursday", comment: "")
        case .friday: NSLocalizedString("weekday.friday", comment: "")
        case .saturday: NSLocalizedString("weekday.saturday", comment: "")
        case .sunday: NSLocalizedString("weekday.sunday", comment: "")
        }
    }

    var shortName: String {
        switch self {
        case .monday: NSLocalizedString("weekday.monday.short", comment: "")
        case .tuesday: NSLocalizedString("weekday.tuesday.short", comment: "")
        case .wednesday: NSLocalizedString("weekday.wednesday.short", comment: "")
        case .thursday: NSLocalizedString("weekday.thursday.short", comment: "")
        case .friday: NSLocalizedString("weekday.friday.short", comment: "")
        case .saturday: NSLocalizedString("weekday.saturday.short", comment: "")
        case .sunday: NSLocalizedString("weekday.sunday.short", comment: "")
        }
    }

    static func from(date: Date, calendar: Calendar = .current) -> WeekDay? {
        WeekDay(rawValue: calendar.component(.weekday, from: date))
    }
}
