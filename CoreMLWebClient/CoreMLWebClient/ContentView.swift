//
//  ContentView.swift
//  CoreMLWebClient
//
//  Created by Andrew Althage on 11/3/23.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @State private var image: UIImage?
    @State private var isImagePickerPresented = false

    var body: some View {
        VStack(spacing: 20) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            Button("Pick Image") {
                isImagePickerPresented = true
            }.buttonStyle(.bordered)
            Button("Upload Image") {
                if let image = image {
                    uploadImage(image: image) { result in
                        switch result {
                        case let .success(success):
                            print("Image was uploaded successfully: \(success)")
                        case let .failure(error):
                            print("Error uploading image: \(error)")
                        }
                    }
                } else {
                    print("nope")
                }
            }.buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker { image in
                self.image = image
            }
        }
    }

    func uploadImage(image: UIImage, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(URLError(.badServerResponse)))
            return
        }

        let url = URL(string: "http://10.11.211.81:8080/upload")! // Adjust path as needed
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.uploadTask(with: request, from: imageData) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            completion(.success(true))
        }
        task.resume()
    }
}

#Preview {
    ContentView()
}
