//
//  ViewModel.swift
//  NearByApp
//
//  Created by kholy on 7/18/20.
//  Copyright © 2020 kholy. All rights reserved.
//

import Foundation
import CoreData
import RxCocoa
import RxSwift
import MapKit
import CoreLocation

protocol ViewModelDelegate{
    func onDataReady()
    func onNoInternet()
}

@available(iOS 12.0, *)
class ViewModel : NSObject{
    
    weak var view:ViewController?
    var delegate : ViewModelDelegate!
    var latestAccessToken: String = ""
    var currentMode : String = UserDefaults.standard.string(forKey: "SAVED_MODE") ?? Modes.singleMode.rawValue
    var currentView : String = UserDefaults.standard.string(forKey: "SAVED_VIEW") ?? View.list.rawValue

    var placesList = [Place]()
    public var placesSubjectList = PublishSubject<[Place]>()
    let disposeBag = DisposeBag()
    var lastLon : Double = 0
    var lastLat : Double = 0
    
    init?(view:ViewController , delegate : ViewModelDelegate){
        self.delegate = delegate
        self.view = view
    }
    
    func callNearByService(){
        if Reachability.isConnectedToNetwork(){
            let getNearByPlacesService = GetNearByPlaces(lon: String(lastLon), lat: String(lastLat))
            getNearByPlacesService.delegate = self
            getNearByPlacesService.showLoader = true
            getNearByPlacesService.execute()
        }else{
            self.retrieveData()
        }
    }
}

extension ViewModel : ServiceDelegate{
    func onSuccess(apiResponse: Any, service: Service) {
        if let response = apiResponse as? [Place]{
            self.placesList = response
            self.delegate.onDataReady()
            if self.placesList.count > 0{
                fillList(currentPlacesList: self.placesList)
                updateData()
            }
        }
    }
    
    func onError(error: Any, service: Service) {
        print(error)
    }
}

extension ViewModel{
    func fillList(currentPlacesList : [Place]){
           for place in currentPlacesList{
              createData(currentPlace: place)
           }
    }
    
    func createData(currentPlace : Place){
       guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let placeObj = PlaceModelData(context: managedContext)
        placeObj.address = currentPlace.address
        placeObj.imgUrl = currentPlace.imgUrl
        placeObj.lat = currentPlace.lat
        placeObj.lon = currentPlace.lon
        placeObj.name = currentPlace.name
       do {
           try managedContext.save()
       } catch let error as NSError {
            debugPrint(error)
       }
    }
    
    func retrieveData(){
        placesList = [Place]()
        var curPlacesList = [Place]()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<PlaceModelData>(entityName: "PlaceModelData")
        do {
            let myPlaces = try managedContext.fetch(fetchRequest) as [PlaceModelData]
            if myPlaces.count == 0{
                self.delegate.onNoInternet()
                return
            }
            for place in myPlaces{
                let myPlace = Place(name: place.name ?? "", address: place.address ?? "", imgUrl: place.imgUrl ?? "", lon: place.lon , lat: place.lat)
                curPlacesList.append(myPlace)
            }
        }catch let error as NSError{
            debugPrint(error)
        }
        let lastCoordinate = CLLocation(latitude: self.lastLat, longitude: self.lastLon)
        for place in curPlacesList{
            let locationCoordinate = CLLocation(latitude: place.lat, longitude: place.lon)
            let distanceInMeters = lastCoordinate.distance(from: locationCoordinate)
            if distanceInMeters < 15000{
                self.placesList.append(place)
            }
        }
        self.placesList = self.placesList.removeDuplicates()
        if self.placesList.count > 0{
            self.delegate.onDataReady()
        }else{
            self.delegate.onNoInternet()
        }
    }
    
    func updateData(){
        var fullPlacesList = [Place]()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<PlaceModelData>(entityName: "PlaceModelData")
        do {
            let myPlaces = try managedContext.fetch(fetchRequest) as [PlaceModelData]
            if myPlaces.count == 0{
                return
            }
            for place in myPlaces{
                let myPlace = Place(name: place.name ?? "", address: place.address ?? "", imgUrl: place.imgUrl ?? "", lon: place.lon , lat: place.lat)
                fullPlacesList.append(myPlace)
            }
        }catch let error as NSError{
            debugPrint(error)
        }
        fullPlacesList = fullPlacesList.removeDuplicates()
        deleteAllEntities()
        fillList(currentPlacesList: fullPlacesList)
    }
    
    func deleteAllEntities(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "PlaceModelData")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        let managedContext = appDelegate.persistentContainer.viewContext
        do
        {
            _ = try managedContext.execute(request)
        } catch let error as NSError {
            debugPrint(error)
        }
    }
}
