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
    @State private var image: UIImage?
    @State private var isImagePickerPresented = false
    @State private var viewModel = ViewModel()
    @State private var sourceType: UIImagePickerController.SourceType = .camera

    @ViewBuilder
    func actionButton() -> some View {
        if let image = image {
            Button("Upload Image") {
                viewModel.upload(image)
            }.buttonStyle(.borderedProminent)
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
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                if let image = image {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }.padding()
                        .frame(maxHeight: 350)
                }
                List {
                    ForEach(viewModel.results, id: \.id) { result in
                        VStack(alignment: .leading) {
                            Text(result.label)
                                .font(.callout)
                            Text(formatAsPercentage(result.confidence))
                                .font(.caption2)
                        }
                    }
                }
            }
            Divider()
            HStack(spacing: 20) {
                actionButton()
                if viewModel.requestStatus == .loading {
                    ProgressView()
                }
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(sourceType: $sourceType) { image in
                self.image = image
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
            Task { @MainActor in
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
