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
    let baseURL = "http://54.148.7.254/" //Server URL
    
    // Different Methods name, will be followed by a .php in the getRequest method
    let setTempMethod = "settemperature"
    let setLocMethod = "setlocation"
    let getDeviceInfoMethod = "getdeviceinfo"
    let getDeviceDataMethod = "getdevicedata"
    
    // The ThermoStat ID
    var deviceID : Int
    
    // User's Mobile ID
    var userID : Int
    
    // If this is true, the user can modify the thermoStat
    var isController : Bool
    
    // List of Sensi Infomation Object, which handles if the household has multiple HVAC
    var sensiInfoAry : [SensiInfo]
    
    // The Learned Curve and Suggested Curve, will be presented as a list of Object
    var pattern : [DeviceData]
    
    // For Core Location
    var locationManager : CLLocationManager
    
    lazy var data = NSMutableData()
    
    
    // Hard code in User and Device Information, both any int from 1-3
    init () {
        deviceID = 1
        userID = 1
        isController = false
        sensiInfoAry = Array<SensiInfo>()
        pattern = Array<DeviceData>()
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        
        // When First load, run this method once to get initial information
        self.getSensiInfo()
        
    }
    
    
    // Handles different methods with different parameters to form a request URL
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
    
    
    // To Set the Sensi to a desired Temperature
    // Assuming the passed in Dictionary with Key named "temperature"
    // Value is the desired temperature to set the Sensi to
    func setTemp(temperatureToSetDict : Dictionary<String, Int>) -> Bool {
        var temp = temperatureToSetDict["temperature"]!
        var toPassIn: [String: String] = ["userkey": "\(userID)", "devicekey": "\(deviceID)", "setpoint": "\(temp)"]
        
        let request = getRequest(setTempMethod, param: toPassIn)

        var toReturn = false
        
        // To Handle the GET request
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(request) {(data, response, error) in
            
            var json = JSON(data: data)
            
            if (json["result"].integerValue == 1) {
                toReturn = true
            }
        }
        
        task.resume()
        
        return toReturn
    }
    
    
    // Utilize Core Location
    // Assume Dictinary["location", tuple (Latitude, Longitude)]
    func setLocation() -> Bool{
        return true
    }
    
    
    // Need to do this periodically
    func getUserLocation() -> (Double, Double) {
        
        return (0.0, 0.0)
    }
    
    
    // Get Wether Information from a third Party API: wunderground.com, pass in ZIP code to get different information
    // For St. Louis, Pass in 63130
    func getWeatherForZip(zipCpde: NSString) -> Dictionary<String, String> {
        var weatherBaseURL = NSURL(string: "http://api.wunderground.com/api/163809ff8d2f1239/conditions/q/MO/\(zipCpde).json")
        
        println("http://api.wunderground.com/api/163809ff8d2f1239/conditions/q/CA/\(zipCpde).json")
        
        var toReturn = Dictionary<String, String>()
        
       
        let task = NSURLSession.sharedSession().dataTaskWithURL(weatherBaseURL!) {(data, response, error) in
            
             var json = JSON(data: data)
            println(json["current_observation"]["temperature_string"].stringValue)
            
            toReturn["temperature"] = json["current_observation"]["temperature_string"].stringValue
            
            println(toReturn["temperature"])
//            toReturn["temp_f"] = json["current_observation"]["temp_f"].stringValue
            
        }
        
        task.resume()
        
        return toReturn
    }
    
    
    
    // Get information From Server to form a list of SensiInfo Object, defined below
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
    
    
    // Get Info from Server to form a list of DeviceData Object, defined Below
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
    // Data point timestamp, it should be a UTC time object, however, is counted as how many seconds
    // were passed from 1970. Therefore is a big integer, this should be the x-axis of the data point
    var timeStamp : Int
    
    // The suggested Temperature of the time point, should y_1
    var suggestedTemp: Float
    
    // The ThermoStat sensed Temperature, should be y_2
    var sensedTemp: Float
    
    init(stamp: Int, suggest: Float, sensed: Float) {
        timeStamp = stamp
        suggestedTemp = suggest
        sensedTemp = sensed
    }
}



class SensiInfo {
    
    var deviceKey : Int // ThermoStat Key
    var deviceName : String // ThermoStat Name
    var isController : Bool // indicating the user who generated this object has the right to change temperature
    var roomTemperature : Float // The current ThermoStat sensed Room Temperature
    var setPointTemperature : Int // The current setting of desired Temperature
    var humidity : Float // The current ThermoStat sensed Room Humidity
    var batteryLevel : Int // The battery Level of the corresponding ThermoStat
    var mode : String // Mode could be off, cool, heat or Fan
    var status : String // I actually forgot about this one, but are you really reading my comments?
    var siteKey : Int // Forgot, just have it there
    var siteName : String // Forgot, just have it there
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
    
    // The printable representation of this object
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