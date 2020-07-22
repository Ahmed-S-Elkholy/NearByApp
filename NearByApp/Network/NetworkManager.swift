//
//  NetworkManager.swift
//  NearByApp
//
//  Created by kholy on 7/19/20.
//  Copyright © 2020 kholy. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

protocol RequestManagerDelegate: class {
    func onSuccess(response: String)
    func onError(response: String)
    func operationFinished()
}

class NetworkManager{
    
    static let requestManager = NetworkManager();
    var delegate: RequestManagerDelegate?

    func BuildRequest(service : Service){
        self.delegate = service
        var url : String = (service.baseUrl) + (service.endPoint)
        url += "?client_id=TKQT4HHWATVBP5J50T4AHREDGTIQYG10R1ZMSUFOPRBSSVJY&client_secret=5JB0NJLHKTBVLKMYTQ05ZHPFEEQDIQWSNZIVC4LMV0IST4WG"
        for i in 0..<service.parameters.count {
            let param = service.parameters[i]
            let key = Array(param.keys)[0]
            let value = param[key]!
            url += "&"
            url += key
            url += "="
            url += value
        }
        self.ExecuteRequest(url: url)
    }
    
    func ExecuteRequest(url : String){
        AF.request(url).responseJSON { response in
            switch response.result {
            case .success:
                debugPrint("Validation Successful")
            case let .failure(error):
                print(error)
            }
        }.responseString { response in
            switch response.result {
            case .success:
                self.delegate?.onSuccess(response: response.value ?? "")
            case let .failure(error):
                print(error)
                self.delegate?.onError(response: error.errorDescription ?? "")
            }
            self.delegate?.operationFinished()
        }
    }
    
}
