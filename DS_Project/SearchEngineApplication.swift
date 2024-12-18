import Vapor

/// Application entry point
public func configure(_ app: Application) throws {
    // 配置路由
    app.get { req in
        return "Search Engine Application is running!"
    }
}

@main
struct SearchEngineApplication {
    static func main() throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        let app = Application(env)
        defer { app.shutdown() }
        try configure(app)
        try app.run()
    }
}
