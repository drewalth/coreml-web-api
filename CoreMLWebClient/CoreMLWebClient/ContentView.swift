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
                    uploadPhoto(image: image, toURL: "http://10.11.211.192:8080/upload") { result in
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

    /// Uploads a photo to a specified URL.
    /// - Parameters:
    ///   - image: The image to be uploaded.
    ///   - url: The URL to which the image should be uploaded.
    ///   - completion: The completion handler to call when the upload is complete.
    func uploadPhoto(image: UIImage, toURL url: String, completion: @escaping (Result<URLResponse, Error>) -> Void) {
        // Ensure the URL is valid
        guard let uploadURL = URL(string: url) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        // Convert the image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            completion(.failure(URLError(.unknown)))
            return
        }

        // Create a URLRequest object
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"

        // Generate boundary string using a unique per-app string
        let boundary = "Boundary-\(UUID().uuidString)"

        // Set the Content-Type header
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // TODO: get actual file name
        // file name
        let imageName = UUID().uuidString

        // Create multipart form body
        let body = createMultipartFormData(boundary: boundary, data: imageData, fileName: imageName)

        // Set the request body
        request.httpBody = body

        // Perform the upload task
        let session = URLSession.shared
        let task = session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let response = response {
                completion(.success(response))
            }
        }
        task.resume()
    }

    /// Creates a multipart/form-data body with the image data.
    /// - Parameters:
    ///   - boundary: The boundary string separating parts of the data.
    ///   - data: The image data to be included in the request.
    ///   - fileName: The filename for the image data in the form-data.
    /// - Returns: A `Data` object representing the multipart/form-data body.
    private func createMultipartFormData(boundary: String, data: Data, fileName: String) -> Data {
        var body = Data()

        // Add the image data to the raw http request data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(data)
        body.append("\r\n")

        // Add the closing boundary
        body.append("--\(boundary)--\r\n")
        return body
    }
}

// Helper function to append string data to Data object
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

#Preview {
    ContentView()
}
