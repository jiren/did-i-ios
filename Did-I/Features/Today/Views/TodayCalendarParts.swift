import SwiftUI
import TipKit

/// The seven days from today: one row as drawn, scrolling sideways at accessibility text sizes.
struct DayStrip: View {
    let days: [DayAgenda.StripDay]
    let onSelect: (CalendarDay) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.horizontal) {
                    cells.padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
            } else {
                cells.padding(.horizontal, 20)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Pick a day"))
    }

    private var cells: some View {
        HStack(spacing: 6) {
            ForEach(days) { day in
                DayStripCell(day: day) { onSelect(day.day) }
                    .frame(width: dynamicTypeSize.isAccessibilitySize ? 104 : nil)
                    .accessibilityIdentifier("strip.\(day.isToday ? "today" : "\(day.dayNumber)")")
            }
        }
    }
}

/// All, then a chip per category (hold one to edit or delete it), then New category. History passes no `onNew`,
/// so it shows the chips alone.
struct CategoryFilter: View {
    let categories: [CategoryRecord]
    let selection: UUID?
    let onSelect: (UUID?) -> Void
    var onNew: (() -> Void)?
    var onEdit: ((UUID) -> Void)?
    var onDelete: ((UUID) -> Void)?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                CategoryChip(title: String(localized: "All"), isSelected: selection == nil) { onSelect(nil) }
                    .accessibilityIdentifier("filter.all")
                ForEach(categories) { category in
                    CategoryChip(
                        title: category.name, icon: category.icon, colour: category.colour,
                        isSelected: selection == category.id
                    ) { onSelect(category.id) }
                    .contextMenu {
                        if let onEdit, let onDelete {
                            CategoryMenu(category: category, onEdit: onEdit, onDelete: onDelete)
                        }
                    }
                    .accessibilityIdentifier("filter.\(category.name)")
                }
                if let onNew {
                    NewCategoryChip(action: onNew)
                        .popoverTip(NewCategoryTip())
                        .autoDismissing(NewCategoryTip())
                        .accessibilityIdentifier("filter.newCategory")
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Filter by category"))
    }
}

/// Edit and Delete for a category (Daily can't be deleted).
struct CategoryMenu: View {
    let category: CategoryRecord
    let onEdit: (UUID) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        Button { onEdit(category.id) } label: { Label("Edit category", systemImage: "pencil") }
        if !category.isDefault {
            Button(role: .destructive) { onDelete(category.id) } label: { Label("Delete category", systemImage: "trash") }
        }
    }
}

/// A due category: its heading (tap to open or close it, + to add), then its tasks as a 3-column grid or a list.
struct TodaySectionView<Menu: View>: View {
    let section: TodaySection
    let layout: TodayLayout
    let onToggle: () -> Void
    let onLog: (UUID) -> Void
    let onPhoto: (PhotoRequest) -> Void
    let onAdd: () -> Void
    @ViewBuilder let menu: (UUID) -> Menu
    let onDrop: (UUID, UUID) -> Void
    let onEdit: (UUID) -> Void
    let onDelete: (UUID) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var width: CGFloat = 350

    /// Three columns as drawn, more on a wide column (iPad, landscape: about 130 pt a tile).
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: max(3, Int(width / 130)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CategorySectionHeader(
                category: section.category, meta: section.meta, progressText: section.progressText,
                isAllDone: section.isAllDone, isExpanded: section.isExpanded, onToggle: onToggle, onAdd: onAdd
            )
            .contextMenu { CategoryMenu(category: section.category, onEdit: onEdit, onDelete: onDelete) }
            if section.isExpanded {
                // Square tiles in one column would be huge at accessibility sizes; rows grow with the text.
                switch dynamicTypeSize.isAccessibilitySize ? .list : layout {
                case .grid:
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(section.tiles) { tile in
                            TaskTile(content: tile.content, onLog: { onLog(tile.id) }, onPhoto: { photo(tile) })
                                .modifier(TaskInteractions(tile: tile, menu: menu, onDrop: onDrop))
                        }
                    }
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
                case .list:
                    LazyVStack(spacing: 6) {
                        ForEach(section.tiles) { tile in
                            TaskRow(content: tile.content, onLog: { onLog(tile.id) }, onPhoto: { photo(tile) })
                                .modifier(TaskInteractions(tile: tile, menu: menu, onDrop: onDrop))
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(section.category.name)
    }

    private func photo(_ tile: TodayTile) {
        onPhoto(PhotoRequest(checkID: tile.id, checkName: tile.content.name))
    }
}

/// A task's menu and drag to reorder, the same in the grid and the list.
private struct TaskInteractions<Menu: View>: ViewModifier {
    let tile: TodayTile
    @ViewBuilder let menu: (UUID) -> Menu
    let onDrop: (UUID, UUID) -> Void

    func body(content: Content) -> some View {
        content
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
}
