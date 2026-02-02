//
//  Track.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import Foundation

struct Track: Identifiable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let album: String
    let trackNumber: Int?
    let artwork: Data?
    let fileURL: URL

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String,
        trackNumber: Int? = nil,
        artwork: Data? = nil,
        fileURL: URL
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.trackNumber = trackNumber
        self.artwork = artwork
        self.fileURL = fileURL
    }
}
