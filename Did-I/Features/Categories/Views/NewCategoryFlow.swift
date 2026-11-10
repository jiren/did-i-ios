import SwiftUI

/// New category: the template gallery, then the form, filled in from the chosen template (or blank).
struct NewCategoryFlow: View {
    @State private var templates: CategoryTemplatesViewModel
    @State private var path: [NewCategoryStart] = []
    /// A fresh editor model for each form.
    let makeEditor: () -> CategoryEditorViewModel
    /// After the category is created.
    let onDone: () -> Void

    /// - Parameter start: a form to open on, over the gallery (Today's template row); nil opens the gallery.
    init(
        templates: @autoclosure () -> CategoryTemplatesViewModel,
        start: NewCategoryStart? = nil,
        makeEditor: @escaping () -> CategoryEditorViewModel,
        onDone: @escaping () -> Void
    ) {
        _templates = State(initialValue: templates())
        _path = State(initialValue: start.map { [$0] } ?? [])
        self.makeEditor = makeEditor
        self.onDone = onDone
    }

    var body: some View {
        NavigationStack(path: $path) {
            CategoryTemplateGallery(viewModel: templates) { path.append($0) }
                .navigationDestination(for: NewCategoryStart.self) { start in
                    CategoryEditorView(viewModel: editor(for: start), isPushed: true, onSaved: onDone)
                }
        }
    }

    private func editor(for start: NewCategoryStart) -> CategoryEditorViewModel {
        let model = makeEditor()
        model.load()
        if case .template(let template) = start { model.apply(template) }
        return model
    }
}
