import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: WekController
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    connectionSection
                    inputSection
                    controlSection
                }
                .padding()
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("wekiosc")
            .confirmationDialog("Delete all Wekinator examples?", isPresented: $confirmDelete) {
                Button("Delete all examples", role: .destructive) { controller.deleteExamples() }
            }
        }
    }

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wekinator connection").font(.headline)
            HStack {
                TextField("Host or IP address", text: $controller.host)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .accessibilityIdentifier("hostField")
                TextField("Port", text: $controller.port)
                    .keyboardType(.numberPad)
                    .frame(width: 74)
                    .accessibilityIdentifier("portField")
            }
            .textFieldStyle(.roundedBorder)
            Button("Connect") { controller.connect() }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("connectButton")
            Text(controller.status).font(.caption).foregroundStyle(.secondary)
            Toggle("Send inputs", isOn: $controller.sendInputs)
                .accessibilityIdentifier("sendInputsSwitch")
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Input source").font(.headline)
            Picker("Input source", selection: Binding(get: { controller.mode },
                                                      set: { controller.setMode($0) })) {
                ForEach(WekController.InputMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            switch controller.mode {
            case .motion:
                Toggle("Acceleration", isOn: $controller.includeAcceleration)
                Toggle("Rotation", isOn: $controller.includeRotation)
                Toggle("Attitude", isOn: $controller.includeAttitude)
                Toggle("Magnetic heading", isOn: $controller.includeHeading)
                Text("Motion needs a real iPhone. Turn on only the values your Wekinator model expects.")
                    .font(.caption).foregroundStyle(.secondary)
            case .pad:
                pad
            case .camera:
                CameraPreview(session: controller.camera.session)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text("A 4 × 5 grid of normalized brightness values is sent. Camera access starts only in this mode.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Text("Rate")
                Slider(value: $controller.rate, in: 5...30, step: 1) { _ in controller.restartTimer() }
                Text("\(Int(controller.rate)) Hz").monospacedDigit()
            }
            if !controller.latestValues.isEmpty {
                Text("Last values: " + controller.latestValues.prefix(4)
                    .map { String(format: "%.2f", $0) }.joined(separator: ", "))
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var pad: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.1))
                Circle().fill(Color.blue).frame(width: 36, height: 36)
                    .position(x: controller.padPoint.x * geometry.size.width,
                              y: controller.padPoint.y * geometry.size.height)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                controller.padPoint = CGPoint(
                    x: min(1, max(0, value.location.x / geometry.size.width)),
                    y: min(1, max(0, value.location.y / geometry.size.height)))
            })
        }
        .frame(height: 260)
        .accessibilityLabel("XY pad")
    }

    private var controlSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Wekinator controls").font(.headline)
            Toggle("Record examples", isOn: Binding(get: { controller.recording },
                                                     set: { controller.setRecording($0) }))
            Toggle("Run model", isOn: Binding(get: { controller.running },
                                              set: { controller.setRunning($0) }))
            HStack {
                Button("Train model") { controller.train() }
                    .buttonStyle(.borderedProminent)
                Button("Delete examples", role: .destructive) { confirmDelete = true }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
