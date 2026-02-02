//
//  ContentView.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.albums.isEmpty {
                    ContentUnavailableView(
                        "No Albums",
                        systemImage: "opticaldisc",
                        description: Text("Import tracks to build your library.")
                    )
                } else {
                    List {
                        ForEach(viewModel.albums) { album in
                            Section {
                                ForEach(album.tracks) { track in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(track.title)
                                                .font(.headline)
                                            Text(track.artist)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        if let trackNumber = track.trackNumber {
                                            Text("#\(trackNumber)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            } header: {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading) {
                                        Text(album.title)
                                            .font(.headline)
                                        Text(album.artist)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        playerViewModel.playAlbum(album)
                                    } label: {
                                        Label("Play Album", systemImage: "play.circle.fill")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.audio, .folder],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    viewModel.importResources(from: urls)
                case .failure:
                    break
                }
            }
            .safeAreaInset(edge: .bottom) {
                PlayerControlsView(viewModel: playerViewModel)
            }
        }
    }
}

private struct PlayerControlsView: View {
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 12) {
            if let currentTrack = viewModel.currentTrack {
                VStack(spacing: 4) {
                    Text(currentTrack.title)
                        .font(.headline)
                    Text(currentTrack.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Select an album to start playback")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 32) {
                Button {
                    viewModel.previous()
                } label: {
                    Image(systemName: "backward.fill")
                }
                .disabled(!viewModel.hasQueue)

                Button {
                    if viewModel.isPlaying {
                        viewModel.pause()
                    } else {
                        viewModel.play()
                    }
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                }
                .disabled(!viewModel.hasQueue)

                Button {
                    viewModel.next()
                } label: {
                    Image(systemName: "forward.fill")
                }
                .disabled(!viewModel.hasQueue)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial)
    }
}

#Preview {
    ContentView()
}
