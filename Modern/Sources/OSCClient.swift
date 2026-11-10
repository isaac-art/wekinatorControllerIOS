import Foundation
import Network

/// OSC 1.0 UDP encoding for the string and float values used by Wekinator.
final class OSCClient {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "uk.ishimura.wekiosc.osc")

    func connect(host: String, port: UInt16) {
        connection?.cancel()
        let newConnection = NWConnection(host: NWEndpoint.Host(host),
                                         port: NWEndpoint.Port(rawValue: port)!, using: .udp)
        newConnection.start(queue: queue)
        connection = newConnection
    }

    func send(_ address: String, floats: [Float] = [], strings: [String] = []) {
        var packet = Data()
        packet.append(padded(address))
        packet.append(padded("," + String(repeating: "s", count: strings.count)
                             + String(repeating: "f", count: floats.count)))
        for value in strings { packet.append(padded(value)) }
        for value in floats {
            var bits = value.bitPattern.bigEndian
            withUnsafeBytes(of: &bits) { packet.append(contentsOf: $0) }
        }
        connection?.send(content: packet, completion: .contentProcessed { _ in })
    }

    private func padded(_ string: String) -> Data {
        var data = Data(string.utf8)
        data.append(0)
        while data.count % 4 != 0 { data.append(0) }
        return data
    }
}
