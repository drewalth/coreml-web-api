//
//  ContentView.swift
//  CoreMLWebClient
//
//  Created by Andrew Althage on 11/3/23.
//

import Foundation
import SwiftUI

enum RequestStatus {
    case loading, success, idle, error
}

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var viewModel = ViewModel()
    @State private var sourceType: UIImagePickerController.SourceType = .camera

    @ViewBuilder
    private func actionButton() -> some View {
        if let image = selectedImage {
            Button("Upload Image") {
                viewModel.upload(image)
            }.buttonStyle(.borderedProminent)
                .disabled(viewModel.requestStatus == .loading)
        } else {
            HStack(spacing: 20) {
                Button("Camera") {
                    sourceType = .camera
                    isImagePickerPresented = true
                }.buttonStyle(.bordered)
                Button("Photo Library") {
                    sourceType = .photoLibrary
                    isImagePickerPresented = true
                }.buttonStyle(.bordered)
            }.padding(.bottom, 20)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.badge.plus")
                                Text("No image selected")
                                    .foregroundColor(.secondary)
                            }.onTapGesture {
                                sourceType = .photoLibrary
                                isImagePickerPresented = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 350)
                    .frame(height: 350)
                }

                actionButton()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                Section("Results") {
                    if viewModel.results.isEmpty {
                        Text("Nothing yet...")
                            .foregroundColor(.secondary)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(viewModel.results, id: \.id) { result in
                            VStack(alignment: .leading, spacing: 1) {
                                Text(result.label)
                                    .font(.callout)
                                Text(formatAsPercentage(result.confidence))
                                    .font(.caption2)
                            }
                        }
                    }
                }

            }.navigationTitle("Classifier")
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(sourceType: $sourceType) { image in
                        self.selectedImage = image
                    }
                }.toolbar {
                    if viewModel.requestStatus == .loading {
                        ProgressView()
                    }
                }
        }
    }

    private func formatAsPercentage(_ value: Float) -> String {
        String(format: "%.2f%%", value * 100)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

// MARK: - ViewModel

extension ContentView {
    @Observable
    class ViewModel {
        var requestStatus: RequestStatus = .idle
        var results: [Classifier.ClassifierResult] = []

        private var classifier = Classifier()

        func upload(_ image: UIImage) {
            Task {
                do {
                    requestStatus = .loading
                    results.removeAll()
                    results = try await classifier.classify(image: image)
                    requestStatus = .success
                } catch {
                    print(error.localizedDescription)
                    requestStatus = .error
                }
            }
        }
    }
}
