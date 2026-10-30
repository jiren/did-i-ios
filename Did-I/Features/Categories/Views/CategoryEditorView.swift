import SwiftUI

/// New category / Edit category (`NewCategory.dc.html`): a full-screen page with a live preview.
struct CategoryEditorView: View {
    @State private var viewModel: CategoryEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    private enum Field { case name, task }

    init(viewModel: @autoclosure () -> CategoryEditorViewModel) {
        _viewModel = State(initialValue: viewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                CategoryPreviewCard(
                    name: viewModel.previewName, icon: viewModel.icon, colour: viewModel.colour,
                    repeatSummary: viewModel.repeatSummary, detail: viewModel.previewDetail
                )
                nameField
                field(String(localized: "Icon")) { CategoryIconGrid(selection: $viewModel.icon, colour: viewModel.colour) }
                field(String(localized: "Colour")) { ColourSwatchPicker(selection: $viewModel.colour) }
                if !viewModel.isDaily {
                    field(String(localized: "Repeat")) { RepeatEditor(viewModel: viewModel) }
                }
                tasks
                reminder
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.didFootnote)
                        .foregroundStyle(Color.tileCoral)
                        .accessibilityIdentifier("category.error")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            // Hidden while typing, so it can't cover the field being edited; Done above the keyboard brings it back.
            if focus == nil {
                Button(viewModel.commitTitle) {
                    if viewModel.save() { dismiss() }
                }
                .buttonStyle(PillButtonStyle(variant: .brand))
                .disabled(!viewModel.canSave)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(Color.ground)
                .accessibilityIdentifier("category.save")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "Done")) {
                    viewModel.addTask()
                    focus = nil
                }
                .font(.didEmphasis)
                .accessibilityIdentifier("category.keyboardDone")
            }
        }
        .background(Color.ground)
        .task { viewModel.load() }
        .onChange(of: viewModel.remindsMe) { _, isOn in
            if isOn { Task { await NotificationPermission.request() } }
        }
    }

    private var header: some View {
        ZStack {
            Text(viewModel.title)
                .font(.didSheetTitle)
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            HStack {
                RoundIconButton(systemName: "xmark", label: String(localized: "Cancel and go back")) { dismiss() }
                    .accessibilityIdentifier("category.close")
                Spacer()
            }
        }
    }

    private var nameField: some View {
        field(String(localized: "Name")) {
            TextField(String(localized: "e.g. Travel, Gym, Leaving work"), text: $viewModel.name)
                .font(.didBody)
                .foregroundStyle(Color.ink)
                .focused($focus, equals: .name)
                .submitLabel(.done)
                .inputField()
                .accessibilityLabel(String(localized: "Name"))
                .accessibilityIdentifier("category.name")
        }
    }

    private var tasks: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tasks").font(.didPill).foregroundStyle(Color.ink)
                Spacer()
                Text(viewModel.taskCountText)
                    .font(.didFootnote)
                    .foregroundStyle(Color.muted)
            }
            ForEach(viewModel.existingTasks, id: \.self) { task in
                HStack(spacing: 12) {
                    Circle().fill(viewModel.colour.background).frame(width: 10, height: 10).accessibilityHidden(true)
                    Text(task).font(.didRowTitle).foregroundStyle(Color.ink)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 52)
                .background(Color.surface, in: .rect(cornerRadius: 16, style: .continuous))
            }
            ForEach(viewModel.newTasks, id: \.self) { task in
                CategoryTaskRow(name: task, colour: viewModel.colour) { viewModel.removeTask(task) }
            }
            HStack(spacing: 8) {
                TextField(String(localized: "Add a task, e.g. Passport packed"), text: $viewModel.taskText)
                    .font(.didBody)
                    .foregroundStyle(Color.ink)
                    .focused($focus, equals: .task)
                    .submitLabel(.next)
                    .onSubmit {
                        viewModel.addTask()
                        // After the submit has resigned the field, so return keeps you typing tasks.
                        Task { focus = .task }
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 52)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.ink, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    }
                    .accessibilityLabel(String(localized: "New task"))
                    .accessibilityIdentifier("category.task")
                Button(action: viewModel.addTask) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.onChrome)
                        .frame(width: 52, height: 52)
                        .background(Color.chrome, in: .rect(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canAddTask)
                .accessibilityLabel(String(localized: "Add task"))
                .accessibilityIdentifier("category.addTask")
            }
        }
    }

    private var reminder: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: $viewModel.remindsMe) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remind me at").font(.didRowTitle).foregroundStyle(Color.ink)
                    Text("Only if something’s not logged").font(.didFootnoteRegular).foregroundStyle(Color.muted)
                }
            }
            .tint(Color.tileViolet)
            .accessibilityIdentifier("category.reminder")
            if viewModel.remindsMe {
                DatePicker(String(localized: "Reminder time"), selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                    .font(.didRowTitle)
                    .foregroundStyle(Color.ink)
                    .padding(.top, 10)
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 12))
        .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.didPill).foregroundStyle(Color.ink)
            content()
        }
        .accessibilityElement(children: .contain)
    }
}

/// The Repeat chips, then the weekday, the day of the month or the date the chosen rule needs.
private struct RepeatEditor: View {
    @Bindable var viewModel: CategoryEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowLayout(spacing: 8) {
                ForEach(RepeatKind.allCases, id: \.self) { kind in
                    ChoiceChip(title: kind.title, isOn: viewModel.repeatKind == kind) { viewModel.repeatKind = kind }
                        .accessibilityIdentifier("category.repeat.\(kind.rawValue)")
                }
            }
            switch viewModel.repeatKind {
            case .daily:
                EmptyView()
            case .weekly, .everyTwoWeeks:
                VStack(alignment: .leading, spacing: 6) {
                    Text("On").font(.didFootnote).foregroundStyle(Color.muted)
                    WeekdayPicker(selection: $viewModel.weekday, colour: viewModel.colour)
                }
            case .monthly:
                HStack {
                    Text("Day of the month").font(.didSubheadline).foregroundStyle(Color.ink)
                    Spacer()
                    Picker(String(localized: "Day of the month"), selection: $viewModel.monthDay) {
                        ForEach(1...31, id: \.self) { Text($0, format: .number).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(Color.ink)
                    .accessibilityIdentifier("category.monthDay")
                }
            case .yearly, .once:
                DatePicker(viewModel.dateLabel, selection: $viewModel.date, displayedComponents: .date)
                    .font(.didSubheadline)
                    .foregroundStyle(Color.muted)
            }
        }
    }
}

private extension View {
    /// The design's text field: white, 16 pt corners, an ink outline.
    func inputField() -> some View {
        padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(Color.surface, in: .rect(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.ink, lineWidth: 2))
    }
}
