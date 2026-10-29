import Foundation
import UIKit

/// Proof photos as HEIC files (plus thumbnails) in the App Group's Photos folder, never the Photos library.
final class PhotoStore: PhotoFileRemoving {
    nonisolated static let defaultFolder = AppGroup.containerURL.appending(path: "Photos", directoryHint: .isDirectory)
    static let maximumDimension: CGFloat = 1600
    static let thumbnailDimension: CGFloat = 480
    private static let thumbnailPrefix = "thumb-"

    let folder: URL
    private let fileManager = FileManager.default

    init(folder: URL = PhotoStore.defaultFolder) {
        self.folder = folder
    }

    /// Saves a downscaled copy and a thumbnail, returning the file name to store on the log.
    func save(_ image: UIImage) throws -> String {
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let name = UUID().uuidString + ".heic"
        try write(image.downscaled(toFit: Self.maximumDimension), to: url(for: name))
        try? write(image.downscaled(toFit: Self.thumbnailDimension), to: thumbnailURL(for: name))
        return name
    }

    func url(for fileName: String) -> URL {
        folder.appending(path: fileName)
    }

    func thumbnailURL(for fileName: String) -> URL {
        folder.appending(path: Self.thumbnailPrefix + fileName)
    }

    func image(named fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path)
    }

    func thumbnail(named fileName: String) -> UIImage? {
        UIImage(contentsOfFile: thumbnailURL(for: fileName).path) ?? image(named: fileName)
    }

    func removePhotos(named fileNames: [String]) {
        for name in fileNames {
            try? fileManager.removeItem(at: url(for: name))
            try? fileManager.removeItem(at: thumbnailURL(for: name))
        }
    }

    /// Photo file names on disk (thumbnails excluded).
    func storedFileNames() -> Set<String> {
        let names = (try? fileManager.contentsOfDirectory(atPath: folder.path)) ?? []
        return Set(names.filter { !$0.hasPrefix(Self.thumbnailPrefix) })
    }

    /// Deletes files no log points at any more (an undone retake, a crash mid-save).
    func removeOrphans(keeping referenced: Set<String>) {
        removePhotos(named: Array(storedFileNames().subtracting(referenced)))
    }

    private func write(_ image: UIImage, to url: URL) throws {
        guard let data = image.heicData() ?? image.jpegData(compressionQuality: 0.8) else {
            throw PhotoError.encodingFailed
        }
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
    }
}

nonisolated enum PhotoError: Error {
    case encodingFailed
}

extension UIImage {
    /// A copy whose longer side is at most `dimension` points at scale 1.
    func downscaled(toFit dimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > dimension else { return self }
        let ratio = dimension / longest
        let target = CGSize(width: (size.width * ratio).rounded(), height: (size.height * ratio).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
