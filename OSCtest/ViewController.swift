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

let address = OSCAddressPattern("/wek/inputs")
var motionManager: CMMotionManager!
var timer = Timer()

class ViewController: UIViewController{
    
    @IBOutlet weak var recSwitch: UISwitch!
    @IBOutlet weak var runSwitch: UISwitch!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var runningLabel: UILabel!
    @IBOutlet weak var trainingButton: UIButton!
    @IBOutlet weak var hostIP: UITextField!
    @IBOutlet weak var hostPort: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        recSwitch.setOn(false, animated: false)
        runSwitch.setOn(false, animated: false)
        
        scheduledTimerWithTimeInterval()
        
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        motionManager.startMagnetometerUpdates()
        
        let message = OSCMessage(OSCAddressPattern("/wekinator/control/setInputNames"), "accelerometerX", "accelerometerY", "accelerometerZ", "rotationX", "rotationY", "rotationZ", "magnetoX", "magnetoY", "magnetoZ")
        client.send(message)
    }

    func scheduledTimerWithTimeInterval(){
        //update 30 times a second
        timer = Timer.scheduledTimer(timeInterval: 1.0/30.0, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    @objc func updateCounting(){
        //print("counting..")
        if let accelerometerData = motionManager.accelerometerData {
            //Mapping the values from -1,1 to 0,1
            let xVal = (accelerometerData.acceleration.x + 1) / 2;
            let yVal = (accelerometerData.acceleration.y + 1) / 2;
            let zVal = (accelerometerData.acceleration.z + 1) / 2;
            
            // TODO: Map these to 0,1
            let xRot = motionManager.gyroData?.rotationRate.x
            let yRot = motionManager.gyroData?.rotationRate.y
            let zRot = motionManager.gyroData?.rotationRate.z
            let xMag = motionManager.magnetometerData?.magneticField.x
            let yMag = motionManager.magnetometerData?.magneticField.y
            let zMag = motionManager.magnetometerData?.magneticField.z
            
            let message = OSCMessage(address, xVal, yVal, zVal, xRot, yRot, zRot, xMag, yMag, zMag)
            client.send(message)
        }
        
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
        if(sender.isOn){
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
}

