import Foundation

nonisolated enum BackupCoding {
    private static let dateStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let secondsDateStyle = Date.ISO8601FormatStyle()

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(dateStyle))
        }
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            if let date = try? dateStyle.parse(text) {
                return date
            }
            if let date = try? secondsDateStyle.parse(text) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: text)
        }
        return decoder
    }
}
