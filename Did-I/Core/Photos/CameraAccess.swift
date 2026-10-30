import AVFoundation
import UIKit

/// Whether the camera can be used for proof photos.
enum CameraAccess {
    enum Status: Equatable {
        case authorized, denied, unavailable
    }

    /// Asks for access the first time, then reports the answer.
    static func requestIfNeeded() async -> Status {
        #if DEBUG
        // The simulator has a camera now; UI tests take the sample-photo path instead of a permission prompt.
        if AppLaunchConfiguration().isUITesting { return .unavailable }
        #endif
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return .unavailable }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video) ? .authorized : .denied
        default: return .denied
        }
    }
}
