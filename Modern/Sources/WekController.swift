import CoreLocation
import CoreMotion
import Foundation
import SwiftUI

@MainActor
final class WekController: NSObject, ObservableObject, CLLocationManagerDelegate {
    enum InputMode: String, CaseIterable, Identifiable {
        case motion = "Motion", pad = "Pad", camera = "Camera"
        var id: String { rawValue }
    }

    @AppStorage("host") var host = "192.168.0.10"
    @AppStorage("port") var port = "6448"
    @Published var mode: InputMode = .motion { didSet { updateNames() } }
    @Published var rate = 20.0
    @Published var sendInputs = false
    @Published var recording = false
    @Published var running = false
    @Published var includeAcceleration = true { didSet { updateNames() } }
    @Published var includeRotation = true { didSet { updateNames() } }
    @Published var includeAttitude = true { didSet { updateNames() } }
    @Published var includeHeading = false { didSet { updateHeading(); updateNames() } }
    @Published var padPoint = CGPoint(x: 0.5, y: 0.5)
    @Published var latestValues: [Float] = []
    @Published var status = "Enter your Wekinator host and tap Connect."

    let camera = CameraSampler()
    private let osc = OSCClient()
    private let motion = CMMotionManager()
    private let location = CLLocationManager()
    private var heading: Double?
    private var timer: Timer?

    override init() {
        super.init()
        location.delegate = self
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        motion.startDeviceMotionUpdates()
        restartTimer()
    }

    func connect() {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty, let number = UInt16(port), number > 0 else {
            status = "Enter a host and a port from 1 to 65535."
            return
        }
        osc.connect(host: trimmedHost, port: number)
        status = "Sending OSC to \(trimmedHost):\(number)"
        updateNames()
    }

    func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / max(rate, 1), repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sendFrame() }
        }
    }

    func setRecording(_ enabled: Bool) {
        recording = enabled
        osc.send(enabled ? "/wekinator/control/startRecording" : "/wekinator/control/stopRecording")
    }

    func setRunning(_ enabled: Bool) {
        running = enabled
        osc.send(enabled ? "/wekinator/control/startRunning" : "/wekinator/control/stopRunning")
    }

    func train() { osc.send("/wekinator/control/train") }
    func deleteExamples() { osc.send("/wekinator/control/deleteAllExamples") }

    func setMode(_ nextMode: InputMode) {
        mode = nextMode
        if nextMode == .camera { camera.start() } else { camera.stop() }
    }

    private func updateNames() {
        let names: [String]
        switch mode {
        case .motion:
            names = (includeAcceleration ? ["accelerometerX", "accelerometerY", "accelerometerZ"] : [])
                + (includeRotation ? ["rotationX", "rotationY", "rotationZ"] : [])
                + (includeAttitude ? ["roll", "pitch", "yaw"] : [])
                + (includeHeading ? ["magneticHeading"] : [])
        case .pad: names = ["padX", "padY"]
        case .camera: names = (0..<20).map { "camera\($0 + 1)" }
        }
        osc.send("/wekinator/control/setInputNames", strings: names)
    }

    private func updateHeading() {
        if includeHeading && CLLocationManager.headingAvailable() {
            location.requestWhenInUseAuthorization()
            location.startUpdatingHeading()
        } else {
            location.stopUpdatingHeading()
            heading = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in self.heading = newHeading.magneticHeading }
    }

    private func sendFrame() {
        guard sendInputs else { return }
        let values: [Float]
        switch mode {
        case .motion:
            guard let data = motion.deviceMotion else { return }
            var result = [Float]()
            if includeAcceleration {
                let a = data.userAcceleration
                result += [normalized(a.x, range: 2), normalized(a.y, range: 2), normalized(a.z, range: 2)]
            }
            if includeRotation {
                let r = data.rotationRate // radians per second
                result += [normalized(r.x, range: 10), normalized(r.y, range: 10), normalized(r.z, range: 10)]
            }
            if includeAttitude {
                let a = data.attitude
                result += [normalized(a.roll, range: .pi), normalized(a.pitch, range: .pi / 2),
                           normalized(a.yaw, range: .pi)]
            }
            if includeHeading { result.append(Float((heading ?? 0) / 360)) }
            values = result
        case .pad:
            values = [Float(padPoint.x), Float(padPoint.y)]
        case .camera:
            guard let frame = camera.samples else { return }
            values = frame
        }
        guard !values.isEmpty else { return }
        latestValues = values
        osc.send("/wek/inputs", floats: values)
    }

    private func normalized(_ value: Double, range: Double) -> Float {
        Float(min(1, max(0, (value / range + 1) / 2)))
    }
}
