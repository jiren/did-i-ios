import SwiftUI

/// The Custom repeat card (Phase 26), like Calendar's: every n days, weeks, months or years, the days it falls on,
/// a start, and when it ends.
struct CustomRepeatEditor: View {
    @Bindable var viewModel: CategoryEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            every
            pattern
            Divider().overlay(Color.line)
            DatePicker(String(localized: "Starts"), selection: $viewModel.customStart, displayedComponents: .date)
                .font(.didRowTitle)
                .foregroundStyle(Color.ink)
                .accessibilityIdentifier("category.repeat.custom.start")
            end
            if viewModel.neverComesUp {
                Text("This doesn’t come up between those dates.")
                    .font(.didFootnote)
                    .foregroundStyle(Color.tileCoral)
                    .accessibilityIdentifier("category.repeat.custom.neverComesUp")
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 12))
        .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
    }

    private var every: some View {
        VStack(alignment: .leading, spacing: 10) {
            Stepper(value: $viewModel.custom.interval, in: CustomRepeat.intervalRange) {
                Text(viewModel.custom.intervalText).font(.didRowTitle).foregroundStyle(Color.ink)
            }
            .accessibilityIdentifier("category.repeat.custom.interval")
            Picker(String(localized: "Repeat every"), selection: $viewModel.custom.unit) {
                ForEach(CustomRepeat.Unit.allCases, id: \.self) { Text(CustomRepeatForm.unitTitle($0)).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("category.repeat.custom.frequency")
        }
    }

    @ViewBuilder private var pattern: some View {
        switch viewModel.custom.unit {
        case .days:
            EmptyView()
        case .weeks:
            VStack(alignment: .leading, spacing: 6) {
                Text("On (pick one or more)").font(.didFootnote).foregroundStyle(Color.muted)
                WeekdayPicker(selection: $viewModel.custom.weekdays, allowsSeveral: true, colour: viewModel.colour, offBackground: .ground)
                    .accessibilityIdentifier("category.repeat.custom.weekdays")
            }
        case .months, .years:
            VStack(alignment: .leading, spacing: 10) {
                if viewModel.custom.unit == .years {
                    row(String(localized: "In")) {
                        menu(String(localized: "Month"), selection: $viewModel.custom.month, id: "month") {
                            ForEach(viewModel.monthChoices, id: \.month) { Text($0.name).tag($0.month) }
                        }
                    }
                }
                Picker(String(localized: "On"), selection: $viewModel.custom.positionChoice) {
                    ForEach(CustomRepeatForm.PositionChoice.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("category.repeat.custom.position")
                switch viewModel.custom.positionChoice {
                case .day:
                    row(String(localized: "Day of the month")) {
                        menu(String(localized: "Day of the month"), selection: $viewModel.custom.monthDay, id: "monthDay") {
                            ForEach(1...31, id: \.self) { Text($0, format: .number).tag($0) }
                        }
                    }
                case .weekday:
                    row(String(localized: "The")) {
                        HStack(spacing: 4) {
                            menu(String(localized: "Which week"), selection: $viewModel.custom.ordinal, id: "ordinal") {
                                ForEach(CustomRepeat.WeekOrdinal.allCases, id: \.self) { Text(CustomRepeatForm.ordinalTitle($0)).tag($0) }
                            }
                            menu(String(localized: "Weekday"), selection: $viewModel.custom.ordinalWeekday, id: "ordinalWeekday") {
                                ForEach(viewModel.weekdayChoices, id: \.weekday) { Text($0.name).tag($0.weekday) }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private var end: some View {
        row(String(localized: "End repeat")) {
            menu(String(localized: "End repeat"), selection: $viewModel.custom.endChoice, id: "end") {
                ForEach(CustomRepeatForm.EndChoice.allCases, id: \.self) { Text($0.title).tag($0) }
            }
        }
        switch viewModel.custom.endChoice {
        case .never:
            EmptyView()
        case .onDate:
            DatePicker(String(localized: "Ends on"), selection: $viewModel.customEnd, in: viewModel.customStart..., displayedComponents: .date)
                .font(.didRowTitle)
                .foregroundStyle(Color.ink)
                .accessibilityIdentifier("category.repeat.custom.endDate")
        case .after:
            Stepper(value: $viewModel.custom.endCount, in: CustomRepeat.countRange) {
                Text(viewModel.custom.endCountText).font(.didRowTitle).foregroundStyle(Color.ink)
            }
            .accessibilityIdentifier("category.repeat.custom.endCount")
        }
    }

    /// A title and its control side by side, or stacked when they don't fit (accessibility sizes).
    private func row<Control: View>(_ title: String, @ViewBuilder control: () -> Control) -> some View {
        let control = control()
        return ViewThatFits(in: .horizontal) {
            HStack {
                Text(title).font(.didRowTitle).foregroundStyle(Color.ink)
                Spacer(minLength: 8)
                control
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.didRowTitle).foregroundStyle(Color.ink)
                control
            }
        }
    }

    private func menu<Value: Hashable, Content: View>(
        _ label: String, selection: Binding<Value>, id: String, @ViewBuilder content: () -> Content
    ) -> some View {
        Picker(label, selection: selection, content: content)
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(Color.ink)
            .accessibilityLabel(label)
            .accessibilityIdentifier("category.repeat.custom.\(id)")
    }
}
