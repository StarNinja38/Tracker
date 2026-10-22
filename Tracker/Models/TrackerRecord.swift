import Foundation

// MARK: - TrackerRecord

/// Отметка о том, что трекер выполнен в конкретный день.
struct TrackerRecord: Hashable {
    let trackerId: UUID
    let date: Date
}
