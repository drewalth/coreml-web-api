import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.routes.defaultMaxBodySize = "10mb"

    // register routes
    try routes(app)
}
