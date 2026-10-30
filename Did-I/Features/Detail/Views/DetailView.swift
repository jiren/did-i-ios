import SwiftUI

/// Check detail (`Detail.dc.html`).
struct DetailView: View {
    @State private var viewModel: DetailViewModel
    @State private var management: CheckManagementRequest?
    @State private var isShowingPhoto = false
    let showsBackButton: Bool
    let onSeeAllHistory: (UUID) -> Void
    let onRemoved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(StoreChangeHub.self) private var changes

    init(
        viewModel: @autoclosure () -> DetailViewModel,
        showsBackButton: Bool = true,
        onSeeAllHistory: @escaping (UUID) -> Void,
        onRemoved: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel())
        self.showsBackButton = showsBackButton
        self.onSeeAllHistory = onSeeAllHistory
        self.onRemoved = onRemoved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if let check = viewModel.check {
                    SwitchRow(
                        title: String(localized: "Nudge me when I leave home"),
                        subtitle: String(localized: "Only if it isn’t logged yet"),
                        symbolName: "bell.fill",
                        isOn: Binding(get: { check.nudgesOnLeavingHome }, set: viewModel.setNudgesOnLeavingHome)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .accessibilityIdentifier("detail.nudge")
                    categoryRow
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                history
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
            }
            .padding(.bottom, 24)
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.ground)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sensoryFeedback(.success, trigger: viewModel.logCount)
        .task {
            viewModel.reload()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                viewModel.rebuild()
            }
        }
        .onChange(of: changes.version) { viewModel.reload() }
        .onChange(of: viewModel.toast) { _, toast in
            if let toast { AccessibilityNotification.Announcement(toast.message).post() }
        }
        .onChange(of: viewModel.check?.nudgesOnLeavingHome) { _, isOn in
            if isOn == true { Task { await NotificationPermission.request() } }
        }
        .onChange(of: viewModel.isRemoved) { _, removed in
            guard removed else { return }
            onRemoved()
            dismiss()
        }
        .fullScreenCover(isPresented: $isShowingPhoto) {
            PhotoViewer(image: viewModel.fullPhoto(), caption: viewModel.latestPhotoCaption)
        }
        .checkManagement(
            $management,
            onRename: { viewModel.rename(to: $1) },
            onPickKind: { viewModel.setKind($1) },
            onRemove: { _ in viewModel.remove() }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                if showsBackButton {
                    RoundIconButton(systemName: "chevron.left", label: String(localized: "Back to Today"), style: .onColor) {
                        dismiss()
                    }
                }
                Spacer()
                Menu {
                    Button { if let check = viewModel.check { management = .rename(check) } } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button { if let check = viewModel.check { management = .icon(check) } } label: {
                        Label("Change icon", systemImage: "square.grid.2x2")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(viewModel.swatch.foreground)
                        .frame(width: 44, height: 44)
                        .background(viewModel.swatch.chip, in: .circle)
                }
                .accessibilityLabel("Edit check")
                Button { management = viewModel.removeRequest } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.didPill)
                        .foregroundStyle(viewModel.swatch.foreground)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(viewModel.swatch.chip, in: .capsule)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove this check")
                .accessibilityIdentifier("detail.remove")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.check?.name ?? "")
                    .font(.didSubheadline)
                    .foregroundStyle(viewModel.swatch.secondary)
                Text(viewModel.headline)
                    .font(.didScreenTitle)
                    .foregroundStyle(viewModel.swatch.foreground)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("detail.headline")
                Text(viewModel.subheadline)
                    .font(.didSubheadline)
                    .foregroundStyle(viewModel.swatch.secondary)
            }
            if let photo = viewModel.latestPhoto {
                Button { isShowingPhoto = true } label: {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 116)
                        .clipShape(.rect(cornerRadius: 22, style: .continuous))
                        .contentShape(.rect(cornerRadius: 22))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Proof photo, \(viewModel.latestPhotoCaption). Opens full screen."))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 24)
        .background(
            viewModel.swatch.background,
            in: UnevenRoundedRectangle(bottomLeadingRadius: 36, bottomTrailingRadius: 36, style: .continuous)
        )
    }

    /// The check's category, with a menu to move it to another.
    private var categoryRow: some View {
        HStack(spacing: 12) {
            if let category = viewModel.category {
                CategoryBadge(icon: category.icon, colour: category.colour, size: 36, cornerRadius: 12)
            }
            Text("Category").font(.didRowTitle).foregroundStyle(Color.ink)
            Spacer(minLength: 8)
            Picker(
                String(localized: "Category"),
                selection: Binding(get: { viewModel.category?.id ?? CategoryDefaults.dailyID }, set: viewModel.moveToCategory)
            ) {
                ForEach(viewModel.categories) { Text($0.name).tag($0.id) }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(Color.linkText)
            .accessibilityIdentifier("detail.category")
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        .frame(minHeight: 52)
        .background(Color.surface, in: .rect(cornerRadius: 18, style: .continuous))
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("History")
                    .font(.didSection)
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(viewModel.countText)
                    .font(.didSubheadline)
                    .foregroundStyle(Color.muted)
                    .accessibilityIdentifier("detail.count")
            }
            .padding(.bottom, 8)
            ForEach(Array(viewModel.timeline.enumerated()), id: \.element.id) { index, item in
                TimelineRow(
                    title: item.title,
                    subtitle: item.subtitle,
                    isNewest: index == 0,
                    isLast: index == viewModel.timeline.count - 1
                )
                .contextMenu {
                    Button(role: .destructive) { viewModel.deleteLog(item.id) } label: {
                        Label("Delete log", systemImage: "trash")
                    }
                }
            }
            if viewModel.hasMoreThanShown {
                Button("See all in History") { onSeeAllHistory(viewModel.checkID) }
                    .font(.didEmphasis)
                    .foregroundStyle(Color.linkText)
                    .frame(minHeight: 44)
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if let toast = viewModel.toast {
                UndoToast(message: toast.message, onUndo: viewModel.undo)
                    .transition(.opacity)
            }
            Button(action: viewModel.logAgain) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.onTile)
                        .frame(width: 28, height: 28)
                        .background(Color.tileSun, in: .circle)
                    Text("Log it again")
                }
            }
            .buttonStyle(PillButtonStyle(variant: .ink, height: 64))
            .accessibilityIdentifier("detail.logAgain")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .animation(.snappy, value: viewModel.toast)
    }
}
