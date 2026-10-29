import Foundation

/// Applies Keep photos and clears orphaned files; run at launch.
enum PhotoRetention {
    static func sweep(logs: any LogStoring, photos: PhotoStore, keep: KeepPhotos, now: Date) {
        if let cutoff = keep.cutoff(before: now), let cleared = try? logs.clearPhotos(olderThan: cutoff) {
            photos.removePhotos(named: cleared)
        }
        if let referenced = try? logs.photoFileNames() {
            photos.removeOrphans(keeping: referenced)
        }
    }
}
