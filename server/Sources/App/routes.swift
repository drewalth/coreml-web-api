import CoreImage
import NIO
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        req.view.render("index.leaf")
    }

    app.post("upload") { req -> EventLoopFuture<HTTPStatus> in

        let logger = Logger(label: "routes.upload")

        logger.info("one")

        let classificationRequest = try req.content.decode(ClassificationRequest.self)

        let imageBuffer = classificationRequest.file.data

        guard let fileData = imageBuffer.getData(at: imageBuffer.readerIndex, length: imageBuffer.readableBytes) else {
            throw Errors.badImageData
        }

        // Convert Data to ByteBuffer
        let buffer = req.application.allocator.buffer(data: fileData)

        // Define the path where the file will be saved
        // You may want to generate a unique filename for each upload
        let path = app.directory.publicDirectory + "uploads/" + classificationRequest.file.filename

        // Check and create the directory if it doesn't exist
        let fileManager = FileManager.default
        let directoryPath = app.directory.publicDirectory + "uploads/"
        if !fileManager.fileExists(atPath: directoryPath) {
            try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        }
        logger.info("two")
        // Write ByteBuffer to disk
        return req.fileio.writeFile(buffer, at: path).map {
            logger.info("three")
            // Return HTTP status after writing the file
            return .ok
        }
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
