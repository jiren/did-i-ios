import Foundation
import SwiftData

extension SchemaV2 {
    /// One time a check was done.
    @Model
    final class LogEntry {
        @Attribute(.unique) var id: UUID
        var date: Date
        /// A `LogSource` raw value.
        var sourceRaw: String
        /// The proof photo's file name in the photo folder, if one was taken.
        var photoFileName: String?
        var check: Check?
        var updatedAt: Date

        init(id: UUID = UUID(), date: Date, source: LogSource, photoFileName: String?, check: Check) {
            self.id = id
            self.date = date
            self.sourceRaw = source.rawValue
            self.photoFileName = photoFileName
            self.check = check
            self.updatedAt = date
        }
    }
}
