//
//  ExportManager.swift
//  PhotoCullingNoLibRaw
//
//  Created by Chris Wang on 2/19/26.
//

import Foundation

enum ExportManager {
    static func exportByRating(assets: [RawAsset]) throws -> URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let root = docs.appendingPathComponent("CullingExport-\(Int(Date().timeIntervalSince1970))", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)

        // create star folders
        for r in 0...5 {
            let dir = root.appendingPathComponent("\(r)_star", isDirectory: true)
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        for a in assets {
            guard let bm = a.bookmark else { continue }
            let url = try SecurityScoped.resolveBookmark(bm)

            try SecurityScoped.withAccess(url) {
                let destDir = root.appendingPathComponent("\(a.rating)_star", isDirectory: true)
                let dest = destDir.appendingPathComponent(a.filename)

                // Avoid overwrite
                if fm.fileExists(atPath: dest.path) {
                    let unique = destDir.appendingPathComponent("\(UUID().uuidString)-\(a.filename)")
                    try fm.moveItem(at: url, to: unique)
                } else {
                    try fm.moveItem(at: url, to: dest)
                }
            }
        }

        return root
    }
}
