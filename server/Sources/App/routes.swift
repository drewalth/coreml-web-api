import CoreImage
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        req.view.render("index.leaf")
    }

    app.post("upload", use: uploadImageHandler)

//    app.post("upload") { req in
//        let input = try req.content.decode(ClassificationRequest.self)
//
//        let path = app.directory.publicDirectory + "uploads/" + input.image.filename
//
//        print(path)
//
//        _ = req.application.fileio.openFile(path: path,
//                                            mode: .write,
//                                            flags: .allowFileCreation(posixMode: 0x744),
//                                            eventLoop: req.eventLoop)
//            .flatMap { handle in
//                req.application.fileio.write(fileHandle: handle,
//                                             buffer: input.image.data,
//                                             eventLoop: req.eventLoop)
//                    .flatMapThrowing { _ in
//                        try handle.close()
//                        return input.image.filename
//                    }
//            }
//        let buffer: ByteBuffer = input.image.data
//
//        let data: Data?
//
//        if let bytes = buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes) {
//            data = Data(bytes)
//        } else {
//            data = nil
//        }
//
//        guard let imageData = data,
//              let ciImage = CIImage(data: imageData)
//        else {
//            return HTTPStatus.internalServerError
//        }
//
//        let results = try Classifier().classify(image: ciImage)
//
//        print(results)
//
//        return HTTPStatus.ok
//    }
}

struct ClassificationRequest: Content {
    var image: File
}

func uploadImageHandler(req: Request) async throws -> HTTPResponseStatus {
    // Define the directory to store the uploaded image temporarily.
    let directory = req.application.directory.workingDirectory + "tmp/"
    let fileManager = FileManager.default

    // Create the directory if it doesn't exist.
    if !fileManager.fileExists(atPath: directory) {
        try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
    }

    // Handle the file upload.
    let uploadedFile = try req.content.decode(File.self)

    // Create a unique file name.
    let filename = "\(UUID().uuidString).\(uploadedFile.extension ?? "jpg")"
    let filePath = directory + filename

    defer {
        print("\nCleaning up...\n")
        try? fileManager.removeItem(atPath: filePath)
        print("\nTemp files removed.\n")
    }

    do {
        print("processing")
        try await req.fileio.writeFile(uploadedFile.data, at: filePath)

        let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))

        guard let ciImage = CIImage(data: fileData) else {
            throw Abort(.badRequest, reason: "Could not create CIImage from uploaded file.")
        }

        let results = try Classifier().classify(image: ciImage)

        print(results)
        print("complete")
        return .ok
    } catch {
        print("\nerror: ", error, "\n")
        throw error
    }
}
