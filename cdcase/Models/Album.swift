//
//  Album.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import Foundation

struct Album: Identifiable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let artwork: Data?
    let tracks: [Track]

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        artwork: Data? = nil,
        tracks: [Track]
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.tracks = tracks
    }
}
