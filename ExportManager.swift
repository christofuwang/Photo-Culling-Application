import Foundation

enum ExportManager {
    static func exportByRating(assets: [RawAsset], to destinationFolder: URL) throws -> URL {
        let fm = FileManager.default

        let ts = Int(Date().timeIntervalSince1970)
        let root = destinationFolder.appendingPathComponent("CullingExport-\(ts)", isDirectory: true)

        try fm.createDirectory(at: root, withIntermediateDirectories: true)

        for r in 0...5 {
            try fm.createDirectory(
                at: root.appendingPathComponent("\(r)_star", isDirectory: true),
                withIntermediateDirectories: true
            )
        }

        for a in assets {
            let destDir = root.appendingPathComponent("\(a.rating)_star", isDirectory: true)
            let dest = destDir.appendingPathComponent(a.filename)

            if fm.fileExists(atPath: dest.path) {
                let unique = destDir.appendingPathComponent("\(UUID().uuidString)-\(a.filename)")
                try fm.copyItem(at: a.originalURL, to: unique)
            } else {
                try fm.copyItem(at: a.originalURL, to: dest)
            }
        }

        return root
    }
}
