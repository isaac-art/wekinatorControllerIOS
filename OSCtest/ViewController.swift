//
//  ViewController.swift
//  OSCtest
//
//  Created by Isaac Clarke on 08/02/2018.
//  Copyright © 2018 Isaac Clarke. All rights reserved.
//

import UIKit
import SwiftOSC

let address = OSCAddressPattern("/wek/inputs")

/*
 
 /wekinator/control/startRecording
 /wekinator/control/stopRecording
 /wekinator/control/train
 /wekinator/control/startRunning
 /wekinator/control/stopRunning
 
 */

class ViewController: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func textField(_ sender: AnyObject) {
        self.view.endEditing(true);
    }

    @IBAction func slider(_ sender: UISlider) {
        let message = OSCMessage(address, sender.value)
        client.send(message)
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
        }else{
            let message = OSCMessage(OSCAddressPattern("/wekinator/control/stopRecording"), 1)
            client.send(message)
        }
    }
    @IBAction func trainButton(_ sender: UIButton) {
        let message = OSCMessage(OSCAddressPattern("/wekinator/control/train"), 1)
        client.send(message)
    }
    
    @IBAction func toggleRunning(_ sender: UISwitch) {
        if(sender.isOn){
            let message = OSCMessage(OSCAddressPattern("/wekinator/control/startRunning"), 1)
            client.send(message)
        }else{
            let message = OSCMessage(OSCAddressPattern("/wekinator/control/stopRunning"), 1)
            client.send(message)
        }
    }
}

