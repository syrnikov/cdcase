//
//  PlaybackController.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import AVFoundation
import MediaPlayer
import UIKit

final class PlaybackController {
    private let player = AVQueuePlayer()
    private let audioSession = AVAudioSession.sharedInstance()
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    private var tracks: [Track] = []
    private var currentIndex: Int = 0

    init() {
        configureAudioSession()
        configureRemoteCommands()
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
        updateNowPlayingInfo(for: currentTrack)
        updatePlaybackState()
    }

    func play() {
        player.play()
        updatePlaybackState()
    }

    func pause() {
        player.pause()
        updatePlaybackState()
    }

    func next() {
        guard currentIndex + 1 < tracks.count else { return }
        currentIndex += 1
        player.advanceToNextItem()
        updateNowPlayingInfo(for: currentTrack)
        updatePlaybackState()
    }

    func previous() {
        guard currentIndex > 0 else {
            player.seek(to: .zero)
            updatePlaybackState()
            return
        }
        currentIndex -= 1
        rebuildQueue(startingAt: currentIndex)
        player.play()
        updateNowPlayingInfo(for: currentTrack)
        updatePlaybackState()
    }

    @objc private func handleItemFinished(_ notification: Notification) {
        guard let finishedItem = notification.object as? AVPlayerItem else { return }
        guard currentIndex + 1 < tracks.count else { return }
        if let asset = finishedItem.asset as? AVURLAsset,
           asset.url == tracks[currentIndex].fileURL {
            currentIndex += 1
        }
        updateNowPlayingInfo(for: currentTrack)
        updatePlaybackState()
    }

    private func rebuildQueue(startingAt index: Int) {
        player.removeAllItems()
        let slice = tracks[index...]
        for track in slice {
            let item = AVPlayerItem(url: track.fileURL)
            player.insert(item, after: nil)
        }
    }

    private func configureAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func configureRemoteCommands() {
        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        remoteCommandCenter.nextTrackCommand.isEnabled = true
        remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }

        remoteCommandCenter.previousTrackCommand.isEnabled = true
        remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }
    }

    private func updateNowPlayingInfo(for track: Track?) {
        guard let track else {
            nowPlayingInfoCenter.nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: track.album
        ]

        if let trackNumber = track.trackNumber {
            info[MPMediaItemPropertyAlbumTrackNumber] = trackNumber
        }

        if let artworkData = track.artwork, let image = UIImage(data: artworkData) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        if let duration = player.currentItem?.asset.duration.seconds, duration.isFinite {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }

        nowPlayingInfoCenter.nowPlayingInfo = info
    }

    private func updatePlaybackState() {
        guard var info = nowPlayingInfoCenter.nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfoCenter.nowPlayingInfo = info
    }
}
