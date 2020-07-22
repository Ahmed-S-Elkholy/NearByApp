//
//  Place.swift
//  NearByApp
//
//  Created by kholy on 7/18/20.
//  Copyright © 2020 kholy. All rights reserved.
//

import Foundation
import SwiftyJSON

class Place {
    
    var name : String = ""
    var address : String = ""
    var imgUrl : String = ""
    var lon : Double = 0
    var lat : Double = 0
    
    init() {
        
    }
    
    init(name:String,address:String,imgUrl:String,lon:Double,lat:Double) {
        self.name = name
        self.address = address
        self.imgUrl = imgUrl
        self.lon = lon
        self.lat = lat
    }
    
    init(response : String) {
        let json = JSON(parseJSON: response)
        
        self.name = json["name"].string ?? "No Name"
        self.address = json["location"]["address"].string ?? "No Address"
        self.lat = json["location"]["lng"].double ?? 0.0
        self.lon = json["location"]["lat"].double ?? 0.0
                
        let prefix = json["categories"][0]["icon"]["prefix"].string ?? ""
        let suffix = json["categories"][0]["icon"]["suffix"].string ?? ""
        
        if prefix.count > 0 && suffix.count > 0{
            self.imgUrl = prefix + "64" + suffix
        }else{
            self.imgUrl = ""
        }
    }
}

extension Place: Equatable{
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.lat == rhs.lat && lhs.lon == rhs.lon
    }
}
