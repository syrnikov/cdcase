//
//  LibraryViewModel.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var albums: [Album] = []

    func importTracks(_ newTracks: [Track]) {
        tracks.append(contentsOf: newTracks)
        rebuildAlbums()
    }

    func removeTrack(id: Track.ID) {
        tracks.removeAll { $0.id == id }
        rebuildAlbums()
    }

    private func rebuildAlbums() {
        let grouped = Dictionary(grouping: tracks) { track in
            "\(track.album)|\(track.artist)"
        }

        albums = grouped.values
            .map { tracks in
                let sortedTracks = tracks.sorted { lhs, rhs in
                    switch (lhs.trackNumber, rhs.trackNumber) {
                    case let (lhsNumber?, rhsNumber?):
                        if lhsNumber == rhsNumber {
                            return lhs.title < rhs.title
                        }
                        return lhsNumber < rhsNumber
                    case (.some, .none):
                        return true
                    case (.none, .some):
                        return false
                    case (.none, .none):
                        return lhs.title < rhs.title
                    }
                }

                let firstTrack = sortedTracks[0]
                return Album(
                    title: firstTrack.album,
                    artist: firstTrack.artist,
                    artwork: firstTrack.artwork,
                    tracks: sortedTracks
                )
            }
            .sorted { lhs, rhs in
                if lhs.artist == rhs.artist {
                    return lhs.title < rhs.title
                }
                return lhs.artist < rhs.artist
            }
    }
}
