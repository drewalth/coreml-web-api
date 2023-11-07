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
    private let logger = Logger(label: "Classifier")

    private func convertCIImageToCGImage(image: CIImage) -> CGImage {
        let context = CIContext(options: nil)
        return context.createCGImage(image, from: image.extent)!
    }

    func classify(image: CIImage) throws -> [ClassifierResult] {
        logger.info("Loading model")
        // load the model.
        let url = Bundle.module.url(forResource: "Resnet50", withExtension: "mlmodelc")!
        guard let model = try? VNCoreMLModel(for: Resnet50(contentsOf: url, configuration: MLModelConfiguration()).model) else {
            throw Errors.unableToLoadMLModel
        }

        logger.info("Setting up Vision Request")
        let request = VNCoreMLRequest(model: model)

        logger.info("Setting up Vision Request Handler")
        let handler = VNImageRequestHandler(ciImage: image)

        logger.info("Classifying image...")
        try? handler.perform([request])

        guard let results = request.results as? [VNClassificationObservation] else {
            throw Errors.noResults
        }

        logger.info("Image classified.")
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
