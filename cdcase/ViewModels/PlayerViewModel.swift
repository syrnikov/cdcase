//
//  PlayerViewModel.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import Combine
import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying = false
    @Published private(set) var hasQueue = false

    private let playbackController = PlaybackController()

    func playAlbum(_ album: Album) {
        playbackController.startPlayback(tracks: album.tracks)
        currentTrack = playbackController.currentTrack
        hasQueue = playbackController.hasQueue
        isPlaying = playbackController.isPlaying
    }

    func play() {
        playbackController.play()
        isPlaying = playbackController.isPlaying
        currentTrack = playbackController.currentTrack
        hasQueue = playbackController.hasQueue
    }

    func pause() {
        playbackController.pause()
        isPlaying = playbackController.isPlaying
    }

    func next() {
        playbackController.next()
        currentTrack = playbackController.currentTrack
        isPlaying = playbackController.isPlaying
    }

    func previous() {
        playbackController.previous()
        currentTrack = playbackController.currentTrack
        isPlaying = playbackController.isPlaying
    }
}
