import Foundation
import Network
import Observation

@MainActor
@Observable
final class TimeSyncService {
    private let host: String
    private let timeout: TimeInterval

    private(set) var offset: TimeInterval = 0
    private(set) var lastSyncedAt: Date?
    private(set) var roundTripDelay: TimeInterval?
    private(set) var lastError: String?
    private(set) var isSyncing: Bool = false

    init(host: String = "time.apple.com", timeout: TimeInterval = 3) {
        self.host = host
        self.timeout = timeout
    }

    func sync() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            let result = try await SNTP.fetchOffset(host: host, timeout: timeout)
            self.offset = result.offset
            self.roundTripDelay = result.delay
            self.lastSyncedAt = Date()
            self.lastError = nil
        } catch {
            self.lastError = (error as? SNTPError)?.userDescription ?? error.localizedDescription
        }
    }

    /// Pre-populate a stable "just synced" state for marketing screenshots,
    /// avoiding any actual network traffic.
    func mockSyncedState(roundTripDelay: TimeInterval = 0.012) {
        self.offset = 0
        self.roundTripDelay = roundTripDelay
        self.lastSyncedAt = Date()
        self.lastError = nil
    }
}

// MARK: - SNTP

enum SNTPError: Error, Equatable {
    case timeout
    case invalidResponse
    case connectionFailed(String)

    var userDescription: String {
        switch self {
        case .timeout: return "Timed out"
        case .invalidResponse: return "Bad response"
        case .connectionFailed(let detail): return detail
        }
    }
}

enum SNTP {
    /// NTP epoch (1900-01-01) is 2_208_988_800 seconds before the Unix epoch (1970-01-01).
    static let ntpEpochOffset: TimeInterval = 2_208_988_800
    private static let twoPow32: TimeInterval = 4_294_967_296

    static func encodeTimestamp(unixSeconds: TimeInterval) -> (seconds: UInt32, fraction: UInt32) {
        let ntp = unixSeconds + ntpEpochOffset
        let seconds = UInt32(ntp)
        let fraction = UInt32((ntp - Double(seconds)) * twoPow32)
        return (seconds, fraction)
    }

    static func decodeTimestamp(seconds: UInt32, fraction: UInt32) -> TimeInterval {
        TimeInterval(seconds) + TimeInterval(fraction) / twoPow32 - ntpEpochOffset
    }

    static func computeOffset(t1: TimeInterval, t2: TimeInterval, t3: TimeInterval, t4: TimeInterval) -> (offset: TimeInterval, delay: TimeInterval) {
        let offset = ((t2 - t1) + (t3 - t4)) / 2
        let delay = (t4 - t1) - (t3 - t2)
        return (offset, delay)
    }

    static func fetchOffset(host: String, port: UInt16 = 123, timeout: TimeInterval) async throws -> (offset: TimeInterval, delay: TimeInterval) {
        let endpoint = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port) ?? .init(integerLiteral: 123)
        let connection = NWConnection(host: endpoint, port: nwPort, using: .udp)

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(offset: TimeInterval, delay: TimeInterval), Error>) in
                let resumer = ContinuationResumer(continuation: continuation, connection: connection)

                let timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                    resumer.resume(.failure(SNTPError.timeout))
                }

                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        var packet = Data(repeating: 0, count: 48)
                        packet[0] = 0x23 // LI=0, VN=4, Mode=3 (client)
                        let t1 = Date().timeIntervalSince1970
                        let encoded = encodeTimestamp(unixSeconds: t1)
                        writeBigEndian(encoded.seconds, to: &packet, at: 40)
                        writeBigEndian(encoded.fraction, to: &packet, at: 44)

                        connection.send(content: packet, completion: .contentProcessed { error in
                            if let error {
                                resumer.resume(.failure(SNTPError.connectionFailed(error.localizedDescription)))
                                return
                            }
                            connection.receiveMessage { data, _, _, error in
                                if let error {
                                    resumer.resume(.failure(SNTPError.connectionFailed(error.localizedDescription)))
                                    return
                                }
                                guard let data, data.count >= 48 else {
                                    resumer.resume(.failure(SNTPError.invalidResponse))
                                    return
                                }
                                let t4 = Date().timeIntervalSince1970
                                let t2Sec = readBigEndian(data, at: 32)
                                let t2Frac = readBigEndian(data, at: 36)
                                let t3Sec = readBigEndian(data, at: 40)
                                let t3Frac = readBigEndian(data, at: 44)
                                let t2 = decodeTimestamp(seconds: t2Sec, fraction: t2Frac)
                                let t3 = decodeTimestamp(seconds: t3Sec, fraction: t3Frac)
                                let computed = computeOffset(t1: t1, t2: t2, t3: t3, t4: t4)
                                resumer.resume(.success(computed))
                            }
                        })
                    case .failed(let error):
                        resumer.resume(.failure(SNTPError.connectionFailed(error.localizedDescription)))
                    default:
                        break
                    }
                }

                connection.start(queue: .global(qos: .userInitiated))
                _ = timeoutTask
            }
        } onCancel: {
            connection.cancel()
        }
    }

    private static func writeBigEndian(_ value: UInt32, to data: inout Data, at offset: Int) {
        data[offset]     = UInt8((value >> 24) & 0xff)
        data[offset + 1] = UInt8((value >> 16) & 0xff)
        data[offset + 2] = UInt8((value >> 8) & 0xff)
        data[offset + 3] = UInt8(value & 0xff)
    }

    private static func readBigEndian(_ data: Data, at offset: Int) -> UInt32 {
        let base = data.startIndex + offset
        return (UInt32(data[base]) << 24)
             | (UInt32(data[base + 1]) << 16)
             | (UInt32(data[base + 2]) << 8)
             |  UInt32(data[base + 3])
    }
}

/// Wraps a continuation so we can guarantee single-resume across the SNTP timeout
/// and Network.framework callback paths, both of which can fire on background queues.
private final class ContinuationResumer: @unchecked Sendable {
    private let continuation: CheckedContinuation<(offset: TimeInterval, delay: TimeInterval), Error>
    private let connection: NWConnection
    private let lock = NSLock()
    private var resumed = false

    init(continuation: CheckedContinuation<(offset: TimeInterval, delay: TimeInterval), Error>, connection: NWConnection) {
        self.continuation = continuation
        self.connection = connection
    }

    func resume(_ result: Result<(offset: TimeInterval, delay: TimeInterval), Error>) {
        lock.lock()
        if resumed { lock.unlock(); return }
        resumed = true
        lock.unlock()
        connection.cancel()
        continuation.resume(with: result)
    }
}
