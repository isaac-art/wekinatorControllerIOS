import AVFoundation
import Foundation
import SwiftUI

/// Samples a 4 × 5 grid of brightness values. Values are always in 0...1.
final class CameraSampler: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published private(set) var samples: [Float]?
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "uk.ishimura.wekiosc.camera")
    private var configured = false
    private var wantsRunning = false
    private var acceptsSamples = false

    func start() {
        acceptsSamples = true
        samples = nil
        queue.async { [weak self] in self?.wantsRunning = true }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.configureAndStart() }
            }
        default: break
        }
    }

    func stop() {
        acceptsSamples = false
        samples = nil
        queue.async { [weak self] in
            self?.wantsRunning = false
            self?.session.stopRunning()
        }
    }

    private func configureAndStart() {
        queue.async { [weak self] in
            guard let self else { return }
            guard self.wantsRunning else { return }
            if !self.configured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .medium
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                    ?? AVCaptureDevice.default(for: .video)
                guard let device, let input = try? AVCaptureDeviceInput(device: device),
                      self.session.canAddInput(input) else {
                    self.session.commitConfiguration()
                    return
                }
                self.session.addInput(input)
                let output = AVCaptureVideoDataOutput()
                output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                output.alwaysDiscardsLateVideoFrames = true
                output.setSampleBufferDelegate(self, queue: self.queue)
                guard self.session.canAddOutput(output) else {
                    self.session.commitConfiguration()
                    return
                }
                self.session.addOutput(output)
                self.session.commitConfiguration()
                self.configured = true
            }
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bytes = base.assumingMemoryBound(to: UInt8.self)
        var values = [Float]()
        for row in 0..<5 {
            for column in 0..<4 {
                let x = min(width - 1, (2 * column + 1) * width / 8)
                let y = min(height - 1, (2 * row + 1) * height / 10)
                let offset = y * rowBytes + x * 4
                let blue = Float(bytes[offset])
                let green = Float(bytes[offset + 1])
                let red = Float(bytes[offset + 2])
                values.append((0.0722 * blue + 0.7152 * green + 0.2126 * red) / 255)
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard self?.acceptsSamples == true else { return }
            self?.samples = values
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.preview.session = session
        view.preview.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var preview: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
