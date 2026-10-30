import SwiftUI

/// More icons: every icon in the library by group, with search; the chosen one sits on the category's colour.
struct IconLibrarySheet: View {
    @Binding var selection: CategoryIcon
    let colour: CategoryColour

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if search.isEmpty {
                        ForEach(IconLibrary.groups) { group in
                            section(group.title, entries: group.entries)
                        }
                    } else {
                        let results = IconLibrary.search(search)
                        if results.isEmpty {
                            Text("No icons match “\(search)”.")
                                .font(.didBody)
                                .foregroundStyle(Color.muted)
                        } else {
                            section(nil, entries: results)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.ground)
            .navigationTitle(Text("More icons"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search icons"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                        .accessibilityIdentifier("icons.done")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.ground)
    }

    private func section(_ title: String?, entries: [IconLibrary.Entry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title { SectionLabel(title: title) }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(entries) { entry in
                    let icon = CategoryIcon(symbol: entry.symbol)
                    let isOn = icon == selection
                    Button {
                        selection = icon
                        dismiss()
                    } label: {
                        Image(systemName: entry.symbol)
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(isOn ? colour.foreground : Color.ink)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(isOn ? colour.background : Color.surface, in: .rect(cornerRadius: 14, style: .continuous))
                            .contentShape(.rect(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(entry.title))
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                    .accessibilityIdentifier("icons.\(entry.symbol)")
                }
            }
        }
    }
}
