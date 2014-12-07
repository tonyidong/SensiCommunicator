//
//  ViewController.swift
//  SensiCommunicator
//
//  Created by Tony Dong on 12/6/14.
//  Copyright (c) 2014 GlobalHackIII. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var magicButton: UIButton!
    
    let communicator = Communicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func magicButtonPressed(sender: AnyObject) {
        var toPassIn: [String: Int] = ["temperature": 78]
        communicator.setTemp(toPassIn)
        for item in communicator.sensiInfoAry {
            item.printMe()
        }
        
        communicator.getPattern(NSDate(timeIntervalSince1970: 12312), endTime: NSDate())
        
        communicator.getWeatherForZip("63130")
        
        
        
        println("*****************************")
        println(communicator.weather["temperature"])
        println("*****************************")
        
        
    }

}

