//
//  MetadataReader.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import AVFoundation
import Foundation

struct TrackMetadata {
    let title: String?
    let artist: String?
    let album: String?
    let trackNumber: Int?
    let artwork: Data?
}

final class MetadataReader {
    func readMetadata(from url: URL) -> TrackMetadata {
        let asset = AVURLAsset(url: url)
        let metadata = asset.commonMetadata

        let title = metadata.stringValue(for: .commonKeyTitle)
        let artist = metadata.stringValue(for: .commonKeyArtist)
        let album = metadata.stringValue(for: .commonKeyAlbumName)
        let trackNumber = metadata.trackNumberValue()
        let artwork = metadata.artworkData()

        return TrackMetadata(
            title: title,
            artist: artist,
            album: album,
            trackNumber: trackNumber,
            artwork: artwork
        )
    }
}

private extension Array where Element == AVMetadataItem {
    func stringValue(for commonKey: AVMetadataKey) -> String? {
        firstItem(matching: commonKey)?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func trackNumberValue() -> Int? {
        guard let item = firstItem(matching: .commonKeyTrackNumber) else {
            return nil
        }

        if let number = item.numberValue?.intValue {
            return number
        }

        if let stringValue = item.stringValue {
            let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let number = Int(trimmed) {
                return number
            }
            if let slashIndex = trimmed.firstIndex(of: "/") {
                let prefix = trimmed[..<slashIndex]
                return Int(prefix)
            }
        }

        return nil
    }

    func artworkData() -> Data? {
        guard let item = firstItem(matching: .commonKeyArtwork) else {
            return nil
        }

        if let data = item.dataValue {
            return data
        }

        if let dictionary = item.value as? [AnyHashable: Any] {
            return dictionary["data"] as? Data
        }

        return nil
    }

    func firstItem(matching commonKey: AVMetadataKey) -> AVMetadataItem? {
        first { item in
            item.commonKey?.rawValue == commonKey.rawValue
        }
    }
}
