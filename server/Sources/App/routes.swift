import CoreImage
import NIO
import Vapor

func routes(_ app: Application) throws {
    app.post("classify") { req -> [ClassifierResult] in
        let classificationReq = try req.content.decode(ClassificationRequest.self)
        let imageBuffer = classificationReq.file.data
        guard let fileData = imageBuffer.getData(at: imageBuffer.readerIndex, length: imageBuffer.readableBytes),
              let ciImage = CIImage(data: fileData)
        else {
            throw Errors.badImageData
        }

        let classifier = Classifier()

        return try classifier.classify(image: ciImage)
    }
}

enum Errors: Error {
    case badImageData
}

struct ClassificationRequest: Content {
    var file: File
}

extension ByteBufferAllocator {
    func buffer(data: Data) -> ByteBuffer {
        var buffer = self.buffer(capacity: data.count)
        buffer.writeBytes(data)
        return buffer
    }
}
