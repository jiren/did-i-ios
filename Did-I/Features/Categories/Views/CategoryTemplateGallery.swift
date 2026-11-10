import SwiftUI

/// What the New category flow pushes: a template, or a blank form.
enum NewCategoryStart: Hashable {
    case template(CategoryTemplate)
    case scratch
}

/// The start of New category (phases 20 and 23): "Start from a template", the templates in sections (Home & safety,
/// Out & about, Health, Family & pets, Money & admin, Habits), then Start from scratch. Picking one opens the form,
/// filled in.
struct CategoryTemplateGallery: View {
    @State private var viewModel: CategoryTemplatesViewModel
    let onPick: (NewCategoryStart) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: @autoclosure () -> CategoryTemplatesViewModel, onPick: @escaping (NewCategoryStart) -> Void) {
        _viewModel = State(initialValue: viewModel())
        self.onPick = onPick
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    Text("New category")
                        .font(.didSheetTitle)
                        .foregroundStyle(Color.ink)
                        .accessibilityAddTraits(.isHeader)
                    HStack {
                        RoundIconButton(systemName: "xmark", label: String(localized: "Cancel and go back")) { dismiss() }
                            .accessibilityIdentifier("templates.close")
                        Spacer()
                    }
                }
                Text("Start from a template")
                    .font(.didBody)
                    .foregroundStyle(Color.muted)
                ForEach(viewModel.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(title: section.title)
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(section.items) { item in
                                TemplateCard(item: item) { onPick(.template(item.template)) }
                                    .accessibilityIdentifier("templates.\(item.template.id)")
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(section.title)
                }
                Button { onPick(.scratch) } label: {
                    Label("Start from scratch", systemImage: "plus")
                        .font(.didRowTitle)
                        .foregroundStyle(Color.linkText)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.disabledFill, style: StrokeStyle(lineWidth: 2.5, dash: [7, 6]))
                        }
                        .contentShape(.rect(cornerRadius: 20))
                }
                .buttonStyle(TilePressStyle())
                .accessibilityIdentifier("templates.scratch")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .task { viewModel.load() }
    }
}
