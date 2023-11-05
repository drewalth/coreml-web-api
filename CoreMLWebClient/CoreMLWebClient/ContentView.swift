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
    @State private var requestStatus: RequestStatus = .idle
    @State private var classifierResults: [ClassifierResult] = []

    @ViewBuilder
    func actionButton() -> some View {
        if let image = image {
            Button("Upload Image") {
                Task {
                    do {
                        requestStatus = .loading
                        classifierResults = try await uploadPhoto(image: image, toURL: "http://10.11.211.192:8080/classify")
                        requestStatus = .success
                    } catch {
                        print(error.localizedDescription)
                        requestStatus = .error
                    }
                }
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
                    ForEach(classifierResults, id: \.id) { result in
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
                if requestStatus == .loading {
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

    /// Uploads a photo to a specified URL.
    /// - Parameters:
    ///   - image: The image to be uploaded.
    ///   - url: The URL to which the image should be uploaded.
    ///   - completion: The completion handler to call when the upload is complete.
//    func uploadPhoto(image: UIImage, toURL url: String, completion: @escaping (Result<URLResponse, Error>) -> Void) {
//        // Ensure the URL is valid
//        guard let uploadURL = URL(string: url) else {
//            completion(.failure(URLError(.badURL)))
//            return
//        }
//
//        // Convert the image to JPEG data
//        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
//            completion(.failure(URLError(.unknown)))
//            return
//        }
//
//        // Create a URLRequest object
//        var request = URLRequest(url: uploadURL)
//        request.httpMethod = "POST"
//
//        // Generate boundary string using a unique per-app string
//        let boundary = "Boundary-\(UUID().uuidString)"
//
//        // Set the Content-Type header
//        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//
//        // TODO: get actual file name
//        // file name
//        let imageName = UUID().uuidString
//
//        // Create multipart form body
//        let body = createMultipartFormData(boundary: boundary, data: imageData, fileName: imageName)
//
//        // Set the request body
//        request.httpBody = body
//
//        // Perform the upload task
//        let session = URLSession.shared
//        let task = session.dataTask(with: request) { _, response, error in
//            if let error = error {
//                completion(.failure(error))
//            } else if let response = response {
//                completion(.success(response))
//            }
//        }
//        task.resume()
//    }
    func uploadPhoto(image: UIImage, toURL url: String) async throws -> [ClassifierResult] {
        // Ensure the URL is valid
        guard let uploadURL = URL(string: url) else {
            throw URLError(.badURL)
        }

        // Convert the image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            throw URLError(.unknown)
        }

        // Generate boundary string using a unique per-app string
        let boundary = "Boundary-\(UUID().uuidString)"

        // Create a URLRequest object
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Create multipart form body
        let body = createMultipartFormData(boundary: boundary, data: imageData, fileName: "photo.jpg")
        request.httpBody = body

        // Perform the upload task
        let (data, response) = try await URLSession.shared.upload(for: request, from: body)

        // Check the response and throw an error if it's not a HTTPURLResponse or the status code is not 200
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Decode the data into an array of ClassifierResult
        let decoder = JSONDecoder()
        let results = try decoder.decode([ClassifierResult].self, from: data)
        return results
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

struct ClassifierResult: Decodable, Identifiable {
    let id = UUID()
    var label: String
    var confidence: Float
}

enum Errors: Error {
    case noSelectedImage
}
