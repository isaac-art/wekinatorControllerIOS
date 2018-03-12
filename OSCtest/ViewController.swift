//
//  ViewController.swift
//  OSCtest
//
//  Created by Isaac Clarke on 08/02/2018.
//  For use with Wekinator created by Rebecca Fiebrink: http://www.wekinator.org/
//
//

import UIKit
import SwiftOSC
import CoreMotion
import CoreLocation
import AVFoundation

var client = OSCClient(address: "192.168.0.10", port: 6448)
let address = OSCAddressPattern("/wek/inputs")
var timer = Timer()
var featureSet = "Motion"

class ViewController: UIViewController, CLLocationManagerDelegate, FrameExtractorDelegate{
    
    @IBOutlet weak var recSwitch: UISwitch!
    @IBOutlet weak var runSwitch: UISwitch!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var runningLabel: UILabel!
    @IBOutlet weak var trainingButton: UIButton!
    @IBOutlet weak var hostIP: UITextField!
    @IBOutlet weak var rateSlider: UISlider!
    @IBOutlet weak var hostPort: UITextField!
   // @IBOutlet weak var outputNumText: UILabel!
    @IBOutlet weak var PadsView: UIView!
    @IBOutlet weak var MotionView: UIView!
    @IBOutlet weak var CameraView: UIImageView!
    
    @IBOutlet weak var accelerometerLabel: UILabel!
    @IBOutlet weak var attitudeLabel: UILabel!
    @IBOutlet weak var rotationLabel: UILabel!
    @IBOutlet weak var magneticHeadingLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var pointer: UIImageView!
    
    var motionManager: CMMotionManager!
    let locationManager = CLLocationManager()
    var magHeading = CLLocationDirection()
    
    var frameExtractor: FrameExtractor!
    
    var xRot = 0.0
    var yRot = 0.0
    var zRot = 0.0
    var roll = 0.0
    var pitch = 0.0
    var yaw = 0.0
    
    @IBOutlet weak var accSwitch: UISwitch!
    @IBOutlet weak var attSwitch: UISwitch!
    @IBOutlet weak var rotSwitch: UISwitch!
    @IBOutlet weak var magSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        MotionView.isHidden = false
        PadsView.isHidden = true
        CameraView.isHidden = true
        recSwitch.setOn(false, animated: false)
        runSwitch.setOn(false, animated: false)
        //outputNumText.text = "1"
        
        scheduledTimerWithTimeInterval()
        
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        motionManager.startDeviceMotionUpdates()
        
        if (CLLocationManager.headingAvailable()) {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self
        }
        
        let message = OSCMessage(OSCAddressPattern("/wekinator/control/setInputNames"), "accelerometerX", "accelerometerY", "accelerometerZ", "rotationX", "rotationY", "rotationZ", "roll", "pitch", "yaw", "magneticHeading")
        client.send(message)
 
        let ms = Int(1000/rateSlider.value)
        rateLabel.text = String("\(ms)ms" )
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        magHeading = heading.magneticHeading
    }
    
    func scheduledTimerWithTimeInterval(){
        //update 30 times a second for motion
        timer = Timer.scheduledTimer(timeInterval: Double(1.0/rateSlider.value), target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    @objc func updateCounting(){
        if(featureSet == "Motion"){
            if let accelerometerData = motionManager.accelerometerData {
                //MAP:  start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1));
                //Mapping the values from -1,1 to 0,1
                let xVal = clamp(((accelerometerData.acceleration.x + 1) / 2), minValue:0.0, maxValue:1.0)
                let yVal = clamp(((accelerometerData.acceleration.y + 1) / 2), minValue:0.0, maxValue:1.0)
                let zVal = clamp(((accelerometerData.acceleration.z + 1) / 2), minValue:0.0, maxValue:1.0)
                
                // gyro
                if(motionManager.deviceMotion?.attitude.roll != nil){
                    //roll Min : -180°, Max : 180°
                    //pitch Min : -90°, Max : 90°
                    //yaw Min : -180°, Max : 180°
                    roll = clamp(((degrees(x:(motionManager.deviceMotion?.attitude.roll)!) + 180) / 360), minValue:0.0, maxValue:1.0)
                    pitch = clamp(((degrees(x:(motionManager.deviceMotion?.attitude.pitch)!) + 90) / 180), minValue:0.0, maxValue:1.0)
                    yaw = clamp(((degrees(x:(motionManager.deviceMotion?.attitude.yaw)!) + 180) / 360), minValue:0.0, maxValue:1.0)
                }
                if(motionManager.gyroData?.rotationRate.x != nil){
                    xRot = clamp(((degrees(x:(motionManager.gyroData?.rotationRate.x)!) + 180) / 360), minValue:0.0, maxValue:1.0)
                    yRot = clamp(((degrees(x:(motionManager.gyroData?.rotationRate.y)!) + 90) / 180), minValue:0.0, maxValue:1.0)
                    zRot = clamp(((degrees(x:(motionManager.gyroData?.rotationRate.z)!) + 180) / 360), minValue:0.0, maxValue:1.0)
                }
                //uncalibrated magnetometer readings
                //let xMag = motionManager.magnetometerData?.magneticField.x
                //let yMag = motionManager.magnetometerData?.magneticField.y
                //let zMag = motionManager.magnetometerData?.magneticField.z
                
                //use locationManagers heading already calibrated
                var mappedMagHeading = 0.0
                if locationManager.heading?.magneticHeading != nil{
                    mappedMagHeading = clamp((magHeading/360), minValue:0.0, maxValue:1.0)
                }
                //send osc message
                let message = OSCMessage(address)
                
                if(accSwitch.isOn){
                    message.add(xVal, yVal, zVal)
                }
                if(rotSwitch.isOn){
                    message.add( xRot, yRot, zRot)
                }
                if(attSwitch.isOn){
                    message.add(roll, pitch, yaw)
                }
                if(magSwitch.isOn){
                    message.add(mappedMagHeading)
                }
                    
                client.send(message)
                
                if(accSwitch.isOn){
                    accelerometerLabel.text = "x: \(xVal) \ny: \(yVal) \nz: \(zVal) "
                }else{
                    accelerometerLabel.text = "off"
                }
                if(attSwitch.isOn){
                    attitudeLabel.text = "roll: \(roll) \npitch: \(pitch) \nyaw: \(yaw)"
                }else{
                     attitudeLabel.text = "off"
                }
                if(rotSwitch.isOn){
                    rotationLabel.text = "x: \(xRot) \ny: \(yRot) \nz: \(zRot)"
                }else{
                    rotationLabel.text = "off"
                }
                if(magSwitch.isOn){
                    magneticHeadingLabel.text = "\(magHeading)"
                }else{
                    magneticHeadingLabel.text = "off"
                }
            }
        }
        else if(featureSet == "Pad"){
            //fit the pointer position value into the bounded area then map
            //MAP:  start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1));
            let xPos = Double( clamp(((pointer.center.x - 25) / 317.5), minValue:0.0, maxValue:1.0 ))
            let yPos =  Double( clamp(((pointer.center.y - 225) / 409.5), minValue:0.0, maxValue:1.0 ))
            //print("x: \(xPos), y: \(yPos)")
            let message = OSCMessage(address,xPos,yPos)
            client.send(message)
        }
        else if(featureSet == "Camera"){
            let pix = CameraView.image?.pixelData()
            //print("0: \(pix![0])")
            //print("1: \(pix![1])")
            //print(pix!.count)
            //691200 values in 360x480 color img
            
            let message = OSCMessage(address,
                                     Double(pix![0]), Double(pix![30960]),
                                     Double(pix![61920]), Double(pix![92880]),
                                     Double(pix![123840]), Double(pix![154800]),
                                     Double(pix![185760]), Double(pix![216720]),
                                     Double(pix![247680]), Double(pix![278640]),
                                     Double(pix![309600]), Double(pix![340560]),
                                     Double(pix![371520]), Double(pix![402480]),
                                     Double(pix![433440]), Double(pix![464400]),
                                     Double(pix![495360]), Double(pix![526420]),
                                     Double(pix![557380]), Double(pix![558240]))
            client.send(message)
        }
    }
    
    
    //CLAMP clamp(newValue, minValue: 0, maxValue: 1)
    public func clamp<T>(_ value: T, minValue: T, maxValue: T) -> T where T : Comparable {
        return min(max(value, minValue), maxValue)
    }
    
    public func degrees(x: Double) -> Double{
       return (180 * x / .pi)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }

    
    var text = "localhost"
    @IBAction func text(_ sender: UITextField) {
        text = sender.text!
        client = OSCClient(address: text, port: 6448)
    }
    
    var portNum = 6448;
    @IBAction func savePort(_ sender: UITextField) {
        if let portNum = Int(sender.text!) {
            client = OSCClient(address: hostIP.text!, port:portNum)
        }
    }
    

    @IBAction func toggleRecording(_ sender: UISwitch) {
        if(recSwitch.isOn){
            let message = OSCMessage(OSCAddressPattern("/wekinator/control/startRecording"), 1)
            client.send(message)
            recordingLabel.text = "RECORDING"
        }else{
            let message = OSCMessage(OSCAddressPattern("/wekinator/control/stopRecording"), 1)
            client.send(message)
            recordingLabel.text = "RECORD"
        }
    }
    
    @IBAction func trainButton(_ sender: UIButton) {
        let message = OSCMessage(OSCAddressPattern("/wekinator/control/train"), 1)
        client.send(message)
        
    }
    
    @IBAction func deleteExamplesButton(_ sender: Any) {
        let message = OSCMessage(OSCAddressPattern("/wekinator/control/deleteAllExamples"), 1)
        client.send(message)
    }
    
    @IBAction func toggleRunning(_ sender: UISwitch) {
        if(sender.isOn){
            let message = OSCMessage(OSCAddressPattern("/wekinator/control/startRunning"), 1)
            client.send(message)
            runningLabel.text = "RUNNING"
        }else{
            let message = OSCMessage(OSCAddressPattern("/wekinator/control/stopRunning"), 1)
            client.send(message)
            runningLabel.text = "RUN"
        }
    }
    
    @IBAction func featureSelector(_ sender: UISegmentedControl) {
        PadsView.isHidden = true
        MotionView.isHidden = true
        CameraView.isHidden = true
        if(sender.selectedSegmentIndex == 0){
            featureSet = "Motion"
            MotionView.isHidden = false
        }else if(sender.selectedSegmentIndex == 1){
            featureSet = "Pad"
             PadsView.isHidden = false
        }else if(sender.selectedSegmentIndex == 2){
            featureSet = "Camera"
            CameraView.isHidden = false
        }
    }
    
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        let location = sender.location(in: self.view)
        let xPos = location.x
        let yPos = location.y
        //print("x: \(xPos), y: \(yPos)")
        if(xPos < 25.0 || xPos > 345.0 || yPos < 225.0 || yPos > 635.0){
            //outofbounds
        }else{
            pointer.center.x = xPos
            pointer.center.y = yPos
        }
    
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        let ms = Int(1000/rateSlider.value)
        rateLabel.text = String("\(ms)ms" )
        timer.invalidate()
        scheduledTimerWithTimeInterval()
    }
    
    
    func captured(image: UIImage) {
        CameraView.image = image
    }
            
//    @IBAction func switchOutput(_ sender: UIStepper) {
//        let message = OSCMessage(OSCAddressPattern("/wekinator/control/outputs"), sender.value)
//        client.send(message)
//        outputNumText.text = String(Int(sender.value))
//
//    }
}

extension UIImage {
    func pixelData() -> [UInt8]? {
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        //let colorSpace = CGColorSpaceCreateDeviceGray() use 2*bytesPerRow
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return pixelData
    }
}
