//
//  RawAsset.swift
//  PhotoCullingNoLibRaw
//
//  Created by Chris Wang on 2/19/26.
//

import Foundation

struct RawAsset: Identifiable, Hashable, Codable {
    let id: UUID
    var filename: String
    var originalURL: URL

    // Security-scoped bookmark so you can reopen later without keeping access open forever.
    var bookmark: Data?

    // Cached preview path inside app sandbox (fast grid loads)
    var cachedPreviewURL: URL?

    // Rating 0...5
    var rating: Int

    init(url: URL, bookmark: Data? = nil) {
        self.id = UUID()
        self.filename = url.lastPathComponent
        self.originalURL = url
        self.bookmark = bookmark
        self.cachedPreviewURL = nil
        self.rating = 0
    }
}
