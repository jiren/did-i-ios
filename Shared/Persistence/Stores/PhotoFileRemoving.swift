import Foundation

/// Deletes proof photo files once no log points at them.
protocol PhotoFileRemoving: AnyObject {
    func removePhotos(named fileNames: [String])
}
