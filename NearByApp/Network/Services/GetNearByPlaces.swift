//
//  GetNearByPlaces.swift
//  NearByApp
//
//  Created by kholy on 7/19/20.
//  Copyright © 2020 kholy. All rights reserved.
//

import Foundation
import SwiftyJSON

class GetNearByPlaces: Service{
    
    init(lon : String, lat : String) {
        super.init()
        self.endPoint = "search"
        
        self.parameters.append(["ll" : "\(lon),\(lat)"])
        
        let date = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        
        var v : String = ""
        
        if month < 10 && day < 10{
           v = "\(year)0\(month)0\(day)"
        }else if month < 10{
            v = "\(year)0\(month)\(day)"
        }else if day < 10{
            v = "\(year)\(month)0\(day)"
        }else{
            v = "\(year)\(month)\(day)"
        }
        
        self.parameters.append(["v" : "\(v)"])
    }
    
    
    override func onSuccess(response: String) {
        var places = [Place]()
        let json = JSON(parseJSON: response)
        let res : JSON = JSON(json["response"])

        if let venues = res["venues"].array{
            if venues.count > 0{
                for venue in venues{
                    let place : Place = Place(response: venue.rawString() ?? "")
                    places.append(place)
                }
            }else{
            }
        }else{
        }
        self.delegate?.onSuccess(apiResponse: places, service: self)
    }
    
    override func onError(response: String) {
        self.delegate?.onError(error: response, service: self)
    }
}
