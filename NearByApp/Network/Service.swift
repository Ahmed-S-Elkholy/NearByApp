//
//  Service.swift
//  NearByApp
//
//  Created by kholy on 7/19/20.
//  Copyright © 2020 kholy. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import PKHUD

protocol ServiceDelegate: class {
    func onSuccess(apiResponse: Any, service: Service);
    func onError(error: Any, service: Service);
}

class Service: RequestManagerDelegate {
    
    internal let requestManager = NetworkManager.requestManager;

    var baseUrl : String = "https://api.foursquare.com/v2/venues/"
    var parameters = [[String : String]]()
    var endPoint : String = ""
    var delegate : ServiceDelegate?
    var showLoader : Bool = false
    
    func execute(){
        if showLoader{
            PKHUD.sharedHUD.contentView = PKHUDProgressView()
            PKHUD.sharedHUD.show()
        }
        self.requestManager.BuildRequest(service: self)
    }
    
    func onSuccess(response: String) {
    }
    
    func onError(response: String) {
    }
    
    func operationFinished(){
        if showLoader{
            PKHUD.sharedHUD.hide()
        }
    }
}
