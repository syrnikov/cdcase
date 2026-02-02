//
//  LibraryViewModel.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import Foundation
import UniformTypeIdentifiers

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var albums: [Album] = []

    private let bookmarkStoreKey = "library.securityScopedBookmarks"

    init() {
        restoreLibraryFromBookmarks()
    }

    func importResources(from urls: [URL]) {
        let bookmarkStore = persistBookmarks(for: urls)
        let resolvedURLs = resolveBookmarks(from: bookmarkStore)
        loadTracks(from: resolvedURLs, shouldReset: false)
    }

    func importTracks(_ newTracks: [Track]) {
        tracks.append(contentsOf: newTracks)
        rebuildAlbums()
    }

    func removeTrack(id: Track.ID) {
        tracks.removeAll { $0.id == id }
        rebuildAlbums()
    }

    private func restoreLibraryFromBookmarks() {
        let storedBookmarks = loadBookmarkStore()
        let resolvedURLs = resolveBookmarks(from: storedBookmarks)
        loadTracks(from: resolvedURLs, shouldReset: true)
    }

    private func persistBookmarks(for urls: [URL]) -> [String: Data] {
        var store = loadBookmarkStore()

        for url in urls {
            do {
                let bookmarkData = try url.bookmarkData(
                    options: [.withSecurityScope],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                store[url.absoluteString] = bookmarkData
            } catch {
                continue
            }
        }

        saveBookmarkStore(store)
        return store
    }

    private func resolveBookmarks(from store: [String: Data]) -> [URL] {
        var updatedStore = store
        var resolved: [URL] = []

        for (key, data) in store {
            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: data,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                resolved.append(url)

                if isStale {
                    if let refreshedData = try? url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        updatedStore[key] = refreshedData
                    }
                }
            } catch {
                continue
            }
        }

        saveBookmarkStore(updatedStore)
        return resolved
    }

    private func loadBookmarkStore() -> [String: Data] {
        guard let stored = UserDefaults.standard.dictionary(forKey: bookmarkStoreKey) as? [String: Data] else {
            return [:]
        }
        return stored
    }

    private func saveBookmarkStore(_ store: [String: Data]) {
        UserDefaults.standard.set(store, forKey: bookmarkStoreKey)
    }

    private func loadTracks(from urls: [URL], shouldReset: Bool) {
        let audioFiles = collectAudioFiles(from: urls)
        let newTracks = audioFiles.map { fileURL in
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            return Track(
                title: fileName,
                artist: "Unknown Artist",
                album: "Unknown Album",
                fileURL: fileURL
            )
        }

        if shouldReset {
            tracks = newTracks
        } else {
            tracks.append(contentsOf: newTracks)
        }

        rebuildAlbums()
    }

    private func collectAudioFiles(from urls: [URL]) -> [URL] {
        var audioFiles: [URL] = []

        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                continue
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            if isDirectory(url) {
                let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.contentTypeKey, .isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )

                while let fileURL = enumerator?.nextObject() as? URL {
                    guard !isDirectory(fileURL) else { continue }
                    if isAudioFile(fileURL) {
                        audioFiles.append(fileURL)
                    }
                }
            } else if isAudioFile(url) {
                audioFiles.append(url)
            }
        }

        return audioFiles
    }

    private func isDirectory(_ url: URL) -> Bool {
        if url.hasDirectoryPath {
            return true
        }
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
        return values?.isDirectory ?? false
    }

    private func isAudioFile(_ url: URL) -> Bool {
        if let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            return contentType.conforms(to: .audio)
        }

        if let fileExtension = url.pathExtension.isEmpty ? nil : url.pathExtension,
           let type = UTType(filenameExtension: fileExtension) {
            return type.conforms(to: .audio)
        }

        return false
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
