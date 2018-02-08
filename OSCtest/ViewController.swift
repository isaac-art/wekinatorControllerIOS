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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        recSwitch.setOn(false, animated: false)
        runSwitch.setOn(false, animated: false)
        scheduledTimerWithTimeInterval()
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
        let message = OSCMessage(OSCAddressPattern("/wekinator/control/setInputNames"), "accelerometerX", "accelerometerY", "accelerometerZ")
        client.send(message)
    }

    func scheduledTimerWithTimeInterval(){
        timer = Timer.scheduledTimer(timeInterval: 0.08, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    @objc func updateCounting(){
        //print("counting..")
        if let accelerometerData = motionManager.accelerometerData {
            //Mapping the values from -1,1 to 0,1
            let xVal = 0 + (1 - 0) * ((accelerometerData.acceleration.x - -1) / (1 - -1));
            let yVal = 0 + (1 - 0) * ((accelerometerData.acceleration.y - -1) / (1 - -1));
            let zVal = 0 + (1 - 0) * ((accelerometerData.acceleration.z - -1) / (1 - -1));
            let message = OSCMessage(address, xVal, yVal, zVal)
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

