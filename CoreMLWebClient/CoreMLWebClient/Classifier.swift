//
//  PhotoManager.swift
//  CoreMLWebClient
//
//  Created by Andrew Althage on 11/4/23.
//

import Foundation
import UIKit

struct Classifier {
    /// replace this with your dev machine IP address
    /// if you are testing with a physical device.
    private let host = "localhost"

    func classify(image: UIImage) async throws -> [ClassifierResult] {
        // Ensure the URL is valid
        guard let uploadURL = URL(string: "http://\(host):8080/classify") else {
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

    struct ClassifierResult: Decodable, Identifiable {
        let id = UUID()
        var label: String
        var confidence: Float
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
