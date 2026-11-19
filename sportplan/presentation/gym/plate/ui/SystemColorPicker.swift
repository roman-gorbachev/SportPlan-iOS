import SwiftUI
import UIKit

struct SystemColorPicker: UIViewControllerRepresentable {
    let initialRGB: Int
    let onSelect: (Int) -> Void
    let onFinish: () -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(onSelect: onSelect, onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.selectedColor = UIColor(plateRGB: initialRGB)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIColorPickerViewController, context: Context) {
        context.coordinator.onSelect = onSelect
        context.coordinator.onFinish = onFinish
    }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var onSelect: (Int) -> Void
        var onFinish: () -> Void

        init(onSelect: @escaping (Int) -> Void, onFinish: @escaping () -> Void) {
            self.onSelect = onSelect
            self.onFinish = onFinish
        }

        func colorPickerViewController(_ picker: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            onSelect(color.plateRGB)
        }

        func colorPickerViewControllerDidFinish(_ picker: UIColorPickerViewController) {
            onFinish()
        }
    }
}
