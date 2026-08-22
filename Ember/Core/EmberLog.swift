import OSLog

enum EmberLog {

    static let subsystem = "com.kenatst.ember"
    static let app = Logger(subsystem: subsystem, category: "app")
}
