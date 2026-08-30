import Foundation

// MARK: - TrackerCategory

/// Категория с вложенными трекерами. Иммутабельна: чтобы добавить трекер,
/// создаётся новая категория с новым массивом.
struct TrackerCategory {
    let title: String
    let trackers: [Tracker]
}
