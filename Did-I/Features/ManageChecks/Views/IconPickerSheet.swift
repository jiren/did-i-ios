import SwiftUI

/// Choose the symbol a check shows.
struct IconPickerSheet: View {
    let checkName: String
    let selected: CheckKind
    let onPick: (CheckKind) -> Void

    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Icon for “\(checkName)”")
                    .font(.didSection)
                    .foregroundStyle(Color.ink)
                Spacer()
                RoundIconButton(systemName: "xmark", label: String(localized: "Close"), style: .sand) { dismiss() }
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(CheckKind.allCases, id: \.self) { kind in
                    Button {
                        onPick(kind)
                        dismiss()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: kind.symbolName)
                                .font(.system(size: 20, weight: .semibold))
                                .frame(width: 48, height: 48)
                                .foregroundStyle(kind == selected ? Color.white : Color.ink)
                                .background(kind == selected ? Color.tileViolet : Color.surface, in: .circle)
                            Text(kind.title)
                                .font(.didFootnote)
                                .foregroundStyle(Color.ink)
                        }
                        .frame(maxWidth: .infinity, minHeight: 76)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(kind.title)
                    .accessibilityAddTraits(kind == selected ? .isSelected : [])
                }
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .background(Color.ground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.ground)
    }
}
