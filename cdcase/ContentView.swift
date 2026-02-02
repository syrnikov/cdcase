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
                                VStack(alignment: .leading) {
                                    Text(album.title)
                                        .font(.headline)
                                    Text(album.artist)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
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
        }
    }
}

#Preview {
    ContentView()
}
