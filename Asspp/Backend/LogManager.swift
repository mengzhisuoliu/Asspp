//
//  LogManager.swift
//  Asspp
//
//  Created on 2026/2/20.
//

import Foundation
import Logging

final nonisolated class LogManager: Sendable {
    static let shared = LogManager()

    private let messageQueue = DispatchQueue(label: "wiki.qaq.log")
    private nonisolated(unsafe) var messages: [String] = []

    func write(_ content: String) {
        messageQueue.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let logMessage = "[\(timestamp)]\n\(content)"
            self.messages.append(logMessage)
        }
    }

    func getMessages() -> [String] {
        messageQueue.sync { messages }
    }
}

struct LogManagerHandler: LogHandler {
    var logLevel: Logger.Level = .debug
    var metadata: Logger.Metadata = [:]
    let label: String

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata _: Logger.Metadata?,
        source _: String,
        file _: String,
        function _: String,
        line _: UInt,
    ) {
        let text = "[\(level)] [\(label)] \(message)"
        Swift.print(text)
        LogManager.shared.write(text)
    }
}
