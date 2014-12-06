//
//  Communicator.swift
//  SensiCommunicator
//
//  Created by Tony Dong on 12/6/14.
//  Copyright (c) 2014 GlobalHackIII. All rights reserved.
//

import Foundation

class Communicator {
    let baseURL = "ec2-54-148-7-254.us-west-2.compute.amazonaws.com/"
    let setTempMethod = "settemprature"
    let setLocMethod = "setlocation"
    let getDeviceInfoMethod = "getdeviceinfo"
    let getDeviceDataMethod = "getdevicedata"
    
    var deviceID : Int
    var userID : Int
    var isController : Bool
    var sensiInfoAry : [SensiInfo]
    var pattern : Dictionary<Int, (Float, Float)>
    
    init () {
        deviceID = 123
        userID = 123
        isController = false
    }
    
    func getRequest(method: String, param: Dictionary<String, String>) -> NSURLRequest {
        var result = baseURL + method + ".php?"
        for key in param.keys {
            result = result + key + "=" + param[key]! + "&"
        }
        var toReturnURL = NSURL(string: result)
        var toReturn = NSURLRequest(URL: toReturnURL!)
        return toReturn
    }
    
    
    // Assuming the passed in Dictionary with Key named "temperature"
    // Value is the desired temperature to set the Sensi to
    func setTemp(temperatureToSetDict : Dictionary<String, Int>) -> Bool {
        var temp = temperatureToSetDict["temperature"]
        var toPassIn: [String: String] = ["userkey": "\(userID)", "devicekey": "\(deviceID)", "setpoint": "\(temp)"]
        
        var request = getRequest(setTempMethod, param: toPassIn)

        var toReturn = false
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            println(NSString(data: data, encoding: NSUTF8StringEncoding))
        }
        
        return toReturn
    }
    
    
    // Assume Dictinary["location", tuple (Latitude, Longitude)]
    func setLocation(locationToSend : Dictionary<String, (Double, Double)>) -> Bool{
        return true
    }
    
    func getSensiInfo() -> ([SensiInfo], userIsController: Bool) {
        var toPassIn: [String: String] = ["userkey": "\(userID)", "devicekey": "\(deviceID)"]
        var request = getRequest(setTempMethod, param: toPassIn)
        
        var toReturnAry = Array<SensiInfo>()
        var toReturnBool = false
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            println(NSString(data: data, encoding: NSUTF8StringEncoding))
            let json = JSON(data: data)
            var upperBound = json["count"].integerValue!
            for i in 1...upperBound {
                toReturnAry.append(SensiInfo(index: i, json: json))
            }
            if toReturnAry[0].isController {
                toReturnBool = true
                self.isController = true
            }
            self.sensiInfoAry = toReturnAry
        }
        return (toReturnAry, toReturnBool)
    }
    
    func getPattern(startTime: NSDate, endTime: NSDate) -> Dictionary<Int, (Float, Float)> {
        
    }
    
    
}

class SensiInfo {
    var deviceKey : Int
    var deviceName : String
    var isController : Bool
    var roomTemperature : Float
    var setPointTemperature : Int
    var humidity : Float
    var batteryLevel : Int
    var mode : String
    var status : String
    var siteKey : Int
    var siteName : String
    var siteTemperature : Float
    
    init(index : Int, json : JSON) {
        deviceKey = json["devices"][index]["devicekey"].integerValue!
        deviceName = json["devices"][index]["devicename"].stringValue!
        isController = json["devices"][index]["privilageLevel"].boolValue
        roomTemperature = json["devices"][index]["roomtemperature"].floatValue!
        setPointTemperature  = json["devices"][index]["setpointtemperature"].integerValue!
        humidity = json["devices"][index]["humidity"].floatValue!
        batteryLevel = json["devices"][index]["batterylevel"].integerValue!
        mode = json["devices"][index]["mode"].stringValue!
        status = json["devices"][index]["status"].stringValue!
        siteKey = json["devices"][index]["sitekey"].integerValue!
        siteName = json["devices"][index]["sitename"].stringValue!
        siteTemperature = json["devices"][index]["sitetemperature"].floatValue!
    }
}