import SwiftUI
import UIKit

/// The system colour picker for a category's custom colour (no opacity).
struct CustomColourPicker: UIViewControllerRepresentable {
    let colour: CategoryColour
    /// 0–1 red, green and blue.
    let onPick: (Double, Double, Double) -> Void

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.title = String(localized: "Custom colour")
        picker.selectedColor = UIColor(colour.background)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIColorPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        let onPick: (Double, Double, Double) -> Void

        init(onPick: @escaping (Double, Double, Double) -> Void) {
            self.onPick = onPick
        }

        func colorPickerViewController(_ picker: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            onPick(Double(red), Double(green), Double(blue))
        }
    }
}
