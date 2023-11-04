//
//  File.swift
//
//
//  Created by Andrew Althage on 11/2/23.
//

import CoreImage
import Vapor
import Vision

struct Classifier {
    private func convertCIImageToCGImage(image: CIImage) -> CGImage {
        let context = CIContext(options: nil)
        return context.createCGImage(image, from: image.extent)!
    }

    func classify(image: CIImage) throws -> [ClassifierResult] {
        print("starting classify")

        var results = [VNClassificationObservation]()

        // Load the model.
        guard let model = try? VNCoreMLModel(for: Resnet50(configuration: MLModelConfiguration()).model) else {
            throw Errors.unableToLoadMLModel
        }

        // Prepare a ml request and wait for results before continuing.
        let semaphore = DispatchSemaphore(value: 1)
        semaphore.wait()
        let request = VNCoreMLRequest(model: model, completionHandler: { request, _ in
            results = request.results as! [VNClassificationObservation]
            semaphore.signal()
        })

        // Make the request.
        let handler = VNImageRequestHandler(cgImage: convertCIImageToCGImage(image: image), options: [:])
        try? handler.perform([request])

        print(#function, results)

        return results.map { ClassifierResult(label: $0.identifier, confidence: $0.confidence) }
    }

    enum Errors: Error {
        case unableToLoadMLModel
    }
}

// extension VNClassificationObservation: Encodable {
//    enum CodingKeys: String, CodingKey {
//        case label
//        case score
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(confidence as Float, forKey: .score)
//        try container.encode(identifier, forKey: .label)
//    }
// }

struct ClassifierResult: Encodable, Content {
    var label: String
    var confidence: Float
}
