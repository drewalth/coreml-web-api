import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.routes.defaultMaxBodySize = "10mb"
    app.views.use(.leaf)
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
