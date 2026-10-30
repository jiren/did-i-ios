import SwiftUI

/// "Add to Daily — Pick as many as you like.", with the category to add to (`Main.dc.html`, `AddChecks.dc.html`).
struct AddChecksSheet: View {
    @State private var viewModel: AddChecksViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCustomFocused: Bool

    init(viewModel: @autoclosure () -> AddChecksViewModel) {
        _viewModel = State(initialValue: viewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                categoryPicker
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.chips, id: \.self) { chip in
                        ChoiceChip(title: chip, isOn: viewModel.isPicked(chip)) { viewModel.toggle(chip) }
                            .accessibilityIdentifier("addChecks.chip.\(chip)")
                    }
                }
                customField
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button(viewModel.commitTitle) {
                if viewModel.commit() { dismiss() }
            }
            .buttonStyle(PillButtonStyle(variant: .brand))
            .disabled(viewModel.pickedCount == 0)
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
            .accessibilityIdentifier("addChecks.commit")
        }
        .background(Color.ground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.ground)
        .presentationCornerRadius(32)
        .task { viewModel.load() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.title)
                    .font(.didSheetTitle)
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Pick as many as you like.")
                    .font(.didCaptionBody)
                    .foregroundStyle(Color.muted)
            }
            Spacer()
            RoundIconButton(systemName: "xmark", label: String(localized: "Close"), style: .sand) { dismiss() }
                .accessibilityIdentifier("addChecks.close")
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Add to")
                .font(.didPill)
                .foregroundStyle(Color.ink)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(viewModel.categories) { category in
                        CategoryChip(
                            title: category.name, icon: category.icon, colour: category.colour,
                            isSelected: category.id == viewModel.categoryID, style: .addTo
                        ) { viewModel.selectCategory(category.id) }
                        .accessibilityIdentifier("addChecks.category.\(category.name)")
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Add to category"))
    }

    private var customField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Something else?")
                .font(.didPill)
                .foregroundStyle(Color.ink)
            HStack(spacing: 8) {
                TextField("e.g. Cat fed", text: $viewModel.customText)
                    .font(.didBody)
                    .foregroundStyle(Color.ink)
                    .focused($isCustomFocused)
                    .submitLabel(.done)
                    .onSubmit(viewModel.addCustom)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 50)
                    .background(Color.surface, in: .rect(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.ink, lineWidth: 2))
                    .accessibilityLabel("Something else?")
                    .accessibilityIdentifier("addChecks.custom")
                Button("Add", action: viewModel.addCustom)
                    .font(.didEmphasis)
                    .foregroundStyle(Color.onChrome)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 50)
                    .background(Color.chrome, in: .rect(cornerRadius: 16, style: .continuous))
                    .disabled(!viewModel.canAddCustom)
                    .accessibilityIdentifier("addChecks.addCustom")
            }
        }
        .padding(.top, 4)
    }
}
