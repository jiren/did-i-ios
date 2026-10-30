import SwiftUI

/// The seven days from today.
struct DayStrip: View {
    let days: [DayAgenda.StripDay]
    let onSelect: (CalendarDay) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days) { day in
                DayStripCell(day: day) { onSelect(day.day) }
                    .accessibilityIdentifier("strip.\(day.isToday ? "today" : "\(day.dayNumber)")")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Pick a day"))
    }
}

/// All, then a chip per category.
struct CategoryFilter: View {
    let categories: [CategoryRecord]
    let selection: UUID?
    let onSelect: (UUID?) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                CategoryChip(title: String(localized: "All"), isSelected: selection == nil) { onSelect(nil) }
                    .accessibilityIdentifier("filter.all")
                ForEach(categories) { category in
                    CategoryChip(
                        title: category.name, icon: category.icon, colour: category.colour,
                        isSelected: selection == category.id
                    ) { onSelect(category.id) }
                    .accessibilityIdentifier("filter.\(category.name)")
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Filter by category"))
    }
}

/// A due category: its heading, then a 3-column grid of tasks and Add task.
struct TodaySectionView<Menu: View>: View {
    let section: TodaySection
    let onLog: (UUID) -> Void
    let onPhoto: (PhotoRequest) -> Void
    let onAdd: () -> Void
    @ViewBuilder let menu: (UUID) -> Menu
    let onDrop: (UUID, UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Three columns as drawn, two at the first accessibility sizes, one beyond.
    private var columns: [GridItem] {
        let count = switch dynamicTypeSize {
        case ..<DynamicTypeSize.accessibility1: 3
        case ..<DynamicTypeSize.accessibility3: 2
        default: 1
        }
        return Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CategorySectionHeader(category: section.category, repeatLabel: section.repeatLabel, progressText: section.progressText)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(section.tiles) { tile in
                    TaskTile(
                        content: tile.content,
                        onLog: { onLog(tile.id) },
                        onPhoto: { onPhoto(PhotoRequest(checkID: tile.id, checkName: tile.content.name)) }
                    )
                    .contextMenu { menu(tile.id) }
                    .draggable(tile.id.uuidString) {
                        TileIcon(kind: tile.content.kind, swatch: tile.content.swatch, isDone: false)
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let dragged = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                        onDrop(dragged, tile.id)
                        return true
                    }
                }
                AddTaskTile(category: section.category, action: onAdd)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(section.category.name)
    }
}
