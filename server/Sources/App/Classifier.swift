//
//  Classifier.swift
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
        // load the model.
        let url = Bundle.module.url(forResource: "Resnet50", withExtension: "mlmodelc")!
        guard let model = try? VNCoreMLModel(for: Resnet50(contentsOf: url, configuration: MLModelConfiguration()).model) else {
            throw Errors.unableToLoadMLModel
        }

        let request = VNCoreMLRequest(model: model)

        let handler = VNImageRequestHandler(ciImage: image)

        try? handler.perform([request])

        guard let results = request.results as? [VNClassificationObservation] else {
            throw Errors.noResults
        }

        return results.map { ClassifierResult(label: $0.identifier, confidence: $0.confidence) }
    }

    enum Errors: Error {
        case unableToLoadMLModel
        case noResults
    }
}

struct ClassifierResult: Encodable, Content {
    var label: String
    var confidence: Float
}
