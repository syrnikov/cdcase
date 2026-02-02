//
//  PlaybackController.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import AVFoundation

final class PlaybackController {
    private let player = AVQueuePlayer()
    private var tracks: [Track] = []
    private var currentIndex: Int = 0

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleItemFinished(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    var currentTrack: Track? {
        guard tracks.indices.contains(currentIndex) else { return nil }
        return tracks[currentIndex]
    }

    var hasQueue: Bool {
        !tracks.isEmpty
    }

    var isPlaying: Bool {
        player.timeControlStatus == .playing
    }

    func startPlayback(tracks: [Track]) {
        self.tracks = tracks
        currentIndex = 0
        rebuildQueue(startingAt: currentIndex)
        player.play()
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func next() {
        guard currentIndex + 1 < tracks.count else { return }
        currentIndex += 1
        player.advanceToNextItem()
    }

    func previous() {
        guard currentIndex > 0 else {
            player.seek(to: .zero)
            return
        }
        currentIndex -= 1
        rebuildQueue(startingAt: currentIndex)
        player.play()
    }

    @objc private func handleItemFinished(_ notification: Notification) {
        guard let finishedItem = notification.object as? AVPlayerItem else { return }
        guard currentIndex + 1 < tracks.count else { return }
        if let asset = finishedItem.asset as? AVURLAsset,
           asset.url == tracks[currentIndex].fileURL {
            currentIndex += 1
        }
    }

    private func rebuildQueue(startingAt index: Int) {
        player.removeAllItems()
        let slice = tracks[index...]
        for track in slice {
            let item = AVPlayerItem(url: track.fileURL)
            player.insert(item, after: nil)
        }
    }
}
