//
//  SecurityScoped.swift
//  PhotoCullingNoLibRaw
//
//  Created by Chris Wang on 2/19/26.
//

import Foundation

enum SecurityScoped {
    static func withAccess<T>(_ url: URL, _ work: () throws -> T) rethrows -> T {
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        return try work()
    }

    static func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    static func resolveBookmark(_ data: Data) throws -> URL {
        var stale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        )
        return url
    }
}
