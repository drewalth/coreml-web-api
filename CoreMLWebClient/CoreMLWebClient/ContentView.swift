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

    @ViewBuilder
    func actionButton() -> some View {
        if let image = image {
            Button("Upload Image") {
                viewModel.upload(image)
            }.buttonStyle(.borderedProminent)
        } else {
            Button("Pick Image") {
                isImagePickerPresented = true
            }.buttonStyle(.bordered)
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
                            Text(result.confidence.formatted())
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
            ImagePicker { image in
                self.image = image
            }
        }
    }
}

#Preview {
    ContentView()
}

enum Errors: Error {
    case noSelectedImage
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
