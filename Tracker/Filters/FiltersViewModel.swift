import Foundation

// MARK: - FiltersViewModel

final class FiltersViewModel {

    var onFilterSelected: Binding<TrackerFilter>?

    let filters = TrackerFilter.allCases

    private let selectedFilter: TrackerFilter

    init(selectedFilter: TrackerFilter) {
        self.selectedFilter = selectedFilter
    }

    func cellViewModel(at index: Int) -> CategoryCellViewModel {
        let filter = filters[index]
        // галочку ставим только у настоящих фильтров
        return CategoryCellViewModel(title: filter.title, isSelected: filter.isActive && filter == selectedFilter)
    }

    func didSelectFilter(at index: Int) {
        guard filters.indices.contains(index) else { return }
        onFilterSelected?(filters[index])
    }
}
