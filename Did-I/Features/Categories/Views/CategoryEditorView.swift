import SwiftUI

/// New category / Edit category (`NewCategory.dc.html`, Phase 20): a full-screen page with a live preview. Opened
/// from the template gallery (pushed, with a back button) or on its own to edit (with a close button).
struct CategoryEditorView: View {
    @State private var viewModel: CategoryEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?
    @State private var isPickingIcon = false
    @State private var isPickingColour = false
    /// Pushed from the template gallery: back goes to the templates.
    let isPushed: Bool
    /// After a save; closes the whole flow.
    let onSaved: () -> Void

    private enum Field: Hashable { case name, task, taskName(UUID) }

    init(viewModel: @autoclosure () -> CategoryEditorViewModel, isPushed: Bool = false, onSaved: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel())
        self.isPushed = isPushed
        self.onSaved = onSaved
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
                field(String(localized: "Icon")) {
                    CategoryIconGrid(selection: $viewModel.icon, colour: viewModel.colour) { isPickingIcon = true }
                }
                field(String(localized: "Colour")) {
                    ColourSwatchPicker(selection: $viewModel.colour) { isPickingColour = true }
                }
                if !viewModel.isDaily {
                    field(String(localized: "Repeat")) { RepeatEditor(viewModel: viewModel) }
                }
                field(String(localized: "Time of day")) { partOfDay }
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
                Button(viewModel.commitTitle, action: save)
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
        .toolbarVisibility(.hidden, for: .navigationBar)
        .sheet(isPresented: $isPickingIcon) {
            IconLibrarySheet(selection: $viewModel.icon, colour: viewModel.colour)
        }
        .sheet(isPresented: $isPickingColour) {
            CustomColourPicker(colour: viewModel.colour, onPick: viewModel.setCustomColour)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            viewModel.removalQuestion ?? "",
            isPresented: Binding(get: { viewModel.removalQuestion != nil }, set: { if !$0 { viewModel.cancelRemoval() } }),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Remove and save"), role: .destructive, action: save)
                .accessibilityIdentifier("category.confirmRemoval")
            Button(String(localized: "Keep them"), role: .cancel) { viewModel.cancelRemoval() }
        } message: {
            Text("Their logs and photos are deleted too.")
        }
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
                RoundIconButton(
                    systemName: isPushed ? "chevron.left" : "xmark",
                    label: isPushed ? String(localized: "Back to templates") : String(localized: "Cancel and go back")
                ) { dismiss() }
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
            ForEach($viewModel.tasks) { $task in
                CategoryTaskRow(name: $task.name, colour: viewModel.colour) {
                    viewModel.removeTask(task.id)
                }
                .focused($focus, equals: .taskName(task.id))
                .draggable(task.id.uuidString) {
                    Text(task.name).font(.didRowTitle).padding(8)
                }
                .dropDestination(for: String.self) { items, _ in
                    guard let dragged = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                    viewModel.moveTask(dragged, to: task.id)
                    return true
                }
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

    /// Morning, Afternoon, Evening or Anytime: where Today groups it.
    private var partOfDay: some View {
        FlowLayout(spacing: 8) {
            ForEach(PartOfDay.allCases, id: \.self) { part in
                ChoiceChip(title: part.title, isOn: viewModel.partOfDay == part) { viewModel.choosePartOfDay(part) }
                    .accessibilityIdentifier("category.partOfDay.\(part.rawValue)")
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
                DatePicker(
                    String(localized: "Reminder time"),
                    selection: Binding(get: { viewModel.reminderTime }, set: viewModel.setReminderTime),
                    displayedComponents: .hourAndMinute
                )
                    .font(.didRowTitle)
                    .foregroundStyle(Color.ink)
                    .padding(.top, 10)
            }
            Divider().overlay(Color.line).padding(.vertical, 10)
            Toggle(isOn: $viewModel.nudgesOnLeavingHome) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nudge me when I leave home").font(.didRowTitle).foregroundStyle(Color.ink)
                    Text("For these tasks, if they aren’t logged yet").font(.didFootnoteRegular).foregroundStyle(Color.muted)
                }
            }
            .tint(Color.tileViolet)
            .accessibilityIdentifier("category.nudge")
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 12))
        .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
    }

    private func save() {
        focus = nil
        guard viewModel.save() else { return }
        // Pushed from the templates, the whole flow closes; on its own, the page does.
        if isPushed { onSaved() } else { dismiss() }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.didPill).foregroundStyle(Color.ink)
            content()
        }
        .accessibilityElement(children: .contain)
    }
}

/// The Repeat chips, then the weekday, the day of the month, the date or the Custom card the chosen rule needs.
private struct RepeatEditor: View {
    @Bindable var viewModel: CategoryEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowLayout(spacing: 8) {
                ForEach(RepeatKind.allCases, id: \.self) { kind in
                    ChoiceChip(title: kind.title, isOn: viewModel.repeatKind == kind) { viewModel.chooseRepeat(kind) }
                        .accessibilityIdentifier("category.repeat.\(kind.rawValue)")
                }
            }
            switch viewModel.repeatKind {
            case .daily:
                EmptyView()
            case .weekly:
                VStack(alignment: .leading, spacing: 6) {
                    Text("On (pick one or more)").font(.didFootnote).foregroundStyle(Color.muted)
                    WeekdayPicker(selection: $viewModel.weekdays, allowsSeveral: true, colour: viewModel.colour)
                }
            case .everyTwoWeeks:
                VStack(alignment: .leading, spacing: 6) {
                    Text("On").font(.didFootnote).foregroundStyle(Color.muted)
                    WeekdayPicker(
                        selection: Binding(get: { [viewModel.weekday] }, set: { viewModel.weekday = $0.first ?? viewModel.weekday }),
                        allowsSeveral: false,
                        colour: viewModel.colour
                    )
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
            case .custom:
                CustomRepeatEditor(viewModel: viewModel)
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
