//
//  ContentView.swift
//  cdcase
//
//  Created by Aaron Syrnikov on 2/2/26.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ContentView: View {
    var body: some View {
        LibraryView()
    }
}

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    @State private var isImporting = false

    private let gridColumns = [GridItem(.adaptive(minimum: 170), spacing: 16)]
    private let backgroundColor = Color(.systemGray6)

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                Group {
                    if viewModel.albums.isEmpty {
                        ContentUnavailableView(
                            "No Albums",
                            systemImage: "opticaldisc",
                            description: Text("Import tracks to build your library.")
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(columns: gridColumns, spacing: 18) {
                                ForEach(viewModel.albums) { album in
                                    AlbumCardView(album: album, backgroundColor: backgroundColor) {
                                        playerViewModel.playAlbum(album)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 80)
                        }
                        .scrollIndicators(.hidden)
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
                PlayerControlsView(viewModel: playerViewModel, backgroundColor: backgroundColor)
            }
        }
        .tint(.accentColor)
    }
}

private struct AlbumCardView: View {
    let album: Album
    let backgroundColor: Color
    let playAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AlbumArtworkView(artwork: album.artwork)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(album.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack {
                Text("\(album.tracks.count) Tracks")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: playAction) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(backgroundColor)
                                .shadow(color: Color.black.opacity(0.35), radius: 4, x: 2, y: 2)
                                .shadow(color: Color.white.opacity(0.08), radius: 4, x: -2, y: -2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Play \(album.title)")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 6, y: 6)
                .shadow(color: Color.white.opacity(0.08), radius: 8, x: -4, y: -4)
        )
    }
}

private struct AlbumArtworkView: View {
    let artwork: Data?

    var body: some View {
        Group {
            if let artwork,
               let image = UIImage(data: artwork) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.black.opacity(0.25), Color.black.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "opticaldisc")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}

private struct PlayerControlsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    let backgroundColor: Color

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
            .buttonStyle(.plain)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 6, y: 6)
                .shadow(color: Color.white.opacity(0.08), radius: 10, x: -4, y: -4)
        )
        .padding([.horizontal, .bottom], 16)
    }
}

#Preview {
    ContentView()
}
