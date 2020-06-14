import Foundation

struct KeyValueItem: Codable {
    init(_ key: String, _ value: String) {
        self.key = key
        self.value = value
    }
    let key: String
    var value: String
}
