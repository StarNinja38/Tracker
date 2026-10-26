import Foundation

enum AccessibilityIdentifiers {
    static let onboardingFinishButton = "onboarding finish"

    static let addTrackerButton = "add tracker"
    static let trackersCollection = "trackers collection"
    static let trackerDoneButton = "tracker done"
    static let trackerUndoneButton = "tracker undone"

    static let habitButton = "habit"
    static let irregularEventButton = "irregular event"
    static let trackerTitleField = "tracker title"
    static let selectionCollection = "selection collection"
    static let cancelTrackerButton = "cancel tracker"
    static let createTrackerButton = "create tracker"

    static let scheduleDoneButton = "schedule done"

    static let addCategoryButton = "add category"
    static let categoriesTable = "categories table"
    static let categoryTitleField = "category title"
    static let categoryDoneButton = "category done"

    static let filtersButton = "filters"
    static let filtersTable = "filters table"

    static func emojiCell(_ emoji: String) -> String {
        "emoji \(emoji)"
    }

    static func colorCell(_ number: Int) -> String {
        "color \(number)"
    }
}
