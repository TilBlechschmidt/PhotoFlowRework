//
//  AssetManager.swift
//  PhotoFlow-ShareExtension
//
//  Created by Til Blechschmidt on 28.09.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation
import CoreGraphics

enum AssetManagerError: Error {
    case thumbnailCreationFailed
}

class AssetManager {
    private unowned let document: Document

    init(document: Document) {
        self.document = document
    }

    func store(from url: URL, origin: AssetOrigin = .files) throws {
        try autoreleasepool {
            let realm = try self.document.createRealm()

            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: url)

            guard let thumbnailData = CGImage.thumbnail(for: data) else {
                throw AssetManagerError.thumbnailCreationFailed
            }

            let asset = Asset()
            asset.origin = origin
            asset.identifier = UUID()
            asset.name = url.deletingPathExtension().lastPathComponent
            asset.uti = url.typeIdentifier ?? "public.image"

            let original = Representation()
            original.type = .original
            original.identifier = data.sha256String()
            asset.representations.append(original)

            let thumbnail = Representation()
            thumbnail.type = .thumbnail
            thumbnail.identifier = thumbnailData.sha256String()
            asset.representations.append(thumbnail)

            realm.beginWrite()
            realm.add(asset)
            try self.document.representationManager.store(data, for: original.identifier)
            try self.document.representationManager.store(thumbnailData, for: thumbnail.identifier)
            try realm.commitWrite()
        }
    }
}