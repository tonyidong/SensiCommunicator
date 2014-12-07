//
//  Communicator.swift
//  SensiCommunicator
//
//  Created by Tony Dong on 12/6/14.
//  Copyright (c) 2014 GlobalHackIII. All rights reserved.
//

import Foundation
import CoreLocation

class Communicator {
    let baseURL = "http://54.148.7.254/"
    let setTempMethod = "settemperature"
    let setLocMethod = "setlocation"
    let getDeviceInfoMethod = "getdeviceinfo"
    let getDeviceDataMethod = "getdevicedata"
    
    var deviceID : Int
    var userID : Int
    var isController : Bool
    var sensiInfoAry : [SensiInfo]
    var pattern : Dictionary<Int, (Float, Float)>
    var locationManager : CLLocationManager
    
    lazy var data = NSMutableData()
    
    init () {
        deviceID = 1
        userID = 1
        isController = false
        sensiInfoAry = Array<SensiInfo>()
        pattern = Dictionary<Int, (Float, Float)>()
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        self.getSensiInfo()
        
    }
    
    func getRequest(method: String, param: Dictionary<String, String>) -> NSURL {
        var result = baseURL + method + ".php?"
        for key in param.keys {
            result = result + key + "=" + param[key]! + "&"
        }
        
        result.substringToIndex(result.endIndex.predecessor())

        var toReturnURL = NSURL(string: result)
        println(result)
        var toReturn = NSURLRequest(URL: toReturnURL!)
        return toReturnURL!
    }
    
    
    // Assuming the passed in Dictionary with Key named "temperature"
    // Value is the desired temperature to set the Sensi to
    func setTemp(temperatureToSetDict : Dictionary<String, Int>) -> Bool {
        var temp = temperatureToSetDict["temperature"]!
        var toPassIn: [String: String] = ["userkey": "\(userID)", "devicekey": "\(deviceID)", "setpoint": "\(temp)"]
        
        let request = getRequest(setTempMethod, param: toPassIn)

        var toReturn = false
        
        
//        var connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: false)!
//        
//        connection.start()
//        let url = NSURL(string: "http://54.148.7.254/settemperature.php?devicekey=1&setpoint=78&userkey=1")
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(request) {(data, response, error) in
            
            var json = JSON(data: data)
            
            if (json["result"].integerValue == 1) {
                toReturn = true
            }
        }
        
        task.resume()
        
        return toReturn
    }
    
    
    // Assume Dictinary["location", tuple (Latitude, Longitude)]
    func setLocation() -> Bool{
        return true
    }
    
    func getUserLocation() -> (Double, Double) {
        
        return (0.0, 0.0)
    }
    
    func getWeatherForZip(zipCpde: NSString) -> Dictionary<String, String> {
//        var weatherBaseString = "http://api.wunderground.com/api/163809ff8d2f1239/conditions/q/CA/\(zipCpde).json"
        var weatherBaseURL = NSURL(string: "http://api.wunderground.com/api/163809ff8d2f1239/conditions/q/CA/\(zipCpde).json")
        
        var toReturn = Dictionary<String, String>()
        
       
        let task = NSURLSession.sharedSession().dataTaskWithURL(weatherBaseURL!) {(data, response, error) in
            
             var json = JSON(data: data)
            
            toReturn["temperature"] = json["temperature_string"].stringValue
            toReturn["temp_f"] = json["temp_f"].stringValue
            
        }
        
        task.resume()
        
        return toReturn
    }
    
    
    func getSensiInfo() -> ([SensiInfo], userIsController: Bool) {
        var toPassIn: [String: String] = ["userkey": "\(userID)", "devicekey": "\(deviceID)"]
        var request = getRequest(getDeviceInfoMethod, param: toPassIn)
        
        var toReturnAry = Array<SensiInfo>()
        var toReturnBool = false
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(request) {(data, response, error) in
            var json = JSON(data: data)
            var len = json["count"].integerValue
            for i in 0...(len!-1) {
                toReturnAry.append(SensiInfo(index: i, json: json))
            }
            if toReturnAry[0].isController {
                toReturnBool = true
                self.isController = true
            }
            self.sensiInfoAry = toReturnAry
            
        }
        
        task.resume()
        

        return (toReturnAry, toReturnBool)
    }
    
    func getPattern(startTime: NSDate, endTime: NSDate) -> [DeviceData] {
        
        var toReturn = Array<DeviceData>()
        
        
        var toPassIn: [String: String] = ["devicekey": "\(deviceID)", "starttime": "\(startTime.timeIntervalSince1970)", "endtime": "\(endTime.timeIntervalSince1970)"]
        var request = getRequest(getDeviceDataMethod, param: toPassIn)
        println(request)
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(request) {(data, response, error) in
            var json = JSON(data: data)
            var len = json["count"].integerValue
            println(json["data"][0]["sugg_temperature"])
            for var i = 0; i < len; i++ {
                toReturn.append(DeviceData(stamp: json["data"][i]["timestamp_utc"].integerValue!, suggest: json["data"][i]["sugg_temperature"].floatValue!, sensed: json["data"][i]["sensed_temperature"].floatValue!))
            }
            
        }
        
        task.resume()
        
        return toReturn
        
    }
    
    
}

class DeviceData {
    var timeStamp : Int
    var suggestedTemp: Float
    var sensedTemp: Float
    
    init(stamp: Int, suggest: Float, sensed: Float) {
        timeStamp = stamp
        suggestedTemp = suggest
        sensedTemp = sensed
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
//    var siteTemperature : Float
    
    init(index : Int, json : JSON) {
        deviceKey = 1
        deviceName = json["devices"][index]["devicename"].stringValue!
        isController = json["devices"][index]["privilageLevel"].boolValue
        roomTemperature = json["devices"][index]["recent_roomtemperature"].floatValue!
        setPointTemperature  = json["devices"][index]["recent_setpointtemperature"].integerValue!
        humidity = json["devices"][index]["recent_humidity"].floatValue!
        batteryLevel = json["devices"][index]["recent_batterylevel"].integerValue!
        mode = json["devices"][index]["recent_mode"].stringValue!
        status = json["devices"][index]["recent_status"].stringValue!
        siteKey = json["devices"][index]["sitekey"].integerValue!
        siteName = json["devices"][index]["sitename"].stringValue!
//        siteTemperature = json["devices"][index]["sitetemperature"].floatValue!
    }
    
    func printMe() {
        var namespace = "deviceKey: " + String(deviceKey) + ", deviceName: " + deviceName
        println("**********" + namespace + "*********")
        println("isController? \(isController)")
        println("Room Temperature: \(roomTemperature), Set to: \(setPointTemperature)")
        println("Humidity: \(humidity)")
        println("batteryLevel: \(batteryLevel), mode: \(mode)")
        println("status: \(status)")
        println("siteKey: \(siteKey), siteName: \(siteName)")
//        println("siteTemperature: \(siteTemperature)")
        
    }
}