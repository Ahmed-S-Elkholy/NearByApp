//
//  ViewController.swift
//  NearByApp
//
//  Created by kholy on 7/18/20.
//  Copyright © 2020 kholy. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import MapKit
import CoreLocation
import EasyTipView
import Kingfisher

enum Modes : String{
    case realTime = "Real Time"
    case singleMode = "Single Mode"
}

enum View : String{
    case list = "list"
    case map = "map"
}

class CustomAnnotation: MKPointAnnotation {
    var place = Place()
    var pinTintColor = UIColor(netHex: 0x5AC8FA)
}

class ViewController: UIViewController {

    @IBOutlet weak var modeButton: UIButton!
    @IBOutlet weak var placesTableView: UITableView!
    @IBOutlet weak var msgImg: UIImageView!
    @IBOutlet weak var msgTxt: UILabel!
    @IBOutlet weak var listView: UIView!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var viewButton: UIButton!
    let locationManager = CLLocationManager()
    var viewModel : ViewModel?
    public var placesSubjectList = PublishSubject<[Place]>()
    let disposeBag = DisposeBag()
    var placeView : EasyTipView!
    var placeText : EasyTipView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel = ViewModel(view: self ,delegate: self)
        self.setupBinding()
        self.viewModel?.placesSubjectList.observeOn(MainScheduler.instance).bind(to:self.placesSubjectList).disposed(by:self.disposeBag)
        self.setLocationManager()
        self.prepareButtons()
    }
    
    func setLocationManager(){
        DispatchQueue.main.async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager.delegate = self
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    func setupBinding(){
        self.modeButton.setTitle(self.viewModel?.currentMode, for: .normal)
        self.viewButton.setTitle(self.viewModel?.currentView, for: .normal)
        self.msgImg.isHidden = true
        self.msgTxt.isHidden = true
        placesTableView.register(UINib(nibName: "PlaceTableViewCell", bundle: nil), forCellReuseIdentifier: "PlaceTableViewCell")
        placesSubjectList.bind(to: placesTableView.rx.items(cellIdentifier: "PlaceTableViewCell", cellType: PlaceTableViewCell.self)) {(row,place,cell) in
            cell.place = place
        }.disposed(by: disposeBag)
        
        /*placesTableView.rx.willDisplayCell
        .subscribe(onNext: ({ (cell,indexPath) in
            cell.alpha = 0
            let transform = CATransform3DTranslate(CATransform3DIdentity, -500, 0, 0)
            cell.layer.transform = transform
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                cell.alpha = 1
                cell.layer.transform = CATransform3DIdentity
            }, completion: nil)
        })).disposed(by: disposeBag)*/
        
        if self.viewModel?.currentView == View.map.rawValue{
            self.mapView.isHidden = false
            self.listView.isHidden = true
            let lastCoordinate = CLLocation(latitude: viewModel!.lastLat, longitude: viewModel!.lastLon)
            render(location: lastCoordinate)
        }else{
            self.mapView.isHidden = true
            self.listView.isHidden = false
        }
    }
    
    func prepareButtons(){
        modeButton.rx.tap.subscribe ({_ in
            if self.viewModel?.currentMode == Modes.singleMode.rawValue{
                self.viewModel?.currentMode = Modes.realTime.rawValue
                self.locationManager.startUpdatingLocation()
            }else{
                self.viewModel?.currentMode = Modes.singleMode.rawValue
                self.locationManager.stopUpdatingLocation()
                DispatchQueue.main.async {
                    self.viewModel?.callNearByService()
                }
            }
            UserDefaults.standard.set(self.viewModel?.currentMode , forKey: "SAVED_MODE")
            self.modeButton.setTitle(self.viewModel?.currentMode, for: .normal)
        })
        
        viewButton.rx.tap.subscribe ({_ in
            if self.viewModel?.currentView == View.list.rawValue{
                self.viewModel?.currentView = View.map.rawValue
                self.mapView.isHidden = false
                self.listView.isHidden = true
            }else{
                self.viewModel?.currentView = View.list.rawValue
                self.mapView.isHidden = true
                self.listView.isHidden = false
                if (self.placeView != nil){
                    self.placeView.dismiss()
                    self.placeText.dismiss()
                }
            }
            if Reachability.isConnectedToNetwork(){
                self.onDataReady()
            }else{
                self.onNoInternet()
            }
            UserDefaults.standard.set(self.viewModel?.currentView , forKey: "SAVED_VIEW")
            self.viewButton.setTitle(self.viewModel?.currentView, for: .normal)
        })
    }
}

//Location And Service Delegate
extension ViewController : ViewModelDelegate, CLLocationManagerDelegate, MKMapViewDelegate{
    func onDataReady() {
        DispatchQueue.main.async {
            if self.viewModel?.currentView == View.map.rawValue{
                for place in self.viewModel!.placesList{
                    let location = CLLocation(latitude: place.lat, longitude: place.lon)
                    self.render(location: location, place: place)
                }
            }else{
                if self.viewModel?.placesList.count ?? 0 > 0{
                    self.msgImg.isHidden = true
                    self.msgTxt.isHidden = true
                    self.placesTableView.isHidden = false
                    self.viewModel?.placesSubjectList.onNext(self.viewModel!.placesList)
                }else{
                    //View No Places Img
                    self.msgImg.isHidden = false
                    self.msgTxt.isHidden = false
                    self.msgImg.image = UIImage(named: "exclamation")
                    self.msgTxt.text = "No Data Found"
                    self.placesTableView.isHidden = true
                }
            }
        }
    }
    
    func onNoInternet(){
        //View No Internet Img
        print("No Saved Data")
        self.msgImg.isHidden = false
        self.msgTxt.isHidden = false
        self.msgImg.image = UIImage(named: "connection-error")
        self.msgTxt.text = "No Internet"
        self.placesTableView.isHidden = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first{
            let lastCoordinate = CLLocation(latitude: viewModel!.lastLat, longitude: viewModel!.lastLon)
            let distanceInMeters = lastCoordinate.distance(from: location)
            if distanceInMeters > 500{
                viewModel?.lastLat = location.coordinate.latitude
                viewModel?.lastLon = location.coordinate.longitude
                DispatchQueue.main.async {
                    self.viewModel?.callNearByService()
                }
            }
            if self.viewModel?.currentMode == Modes.singleMode.rawValue{
                self.locationManager.stopUpdatingLocation()
            }
            
            if self.viewModel?.currentView == View.map.rawValue{
                render(location: location)
            }
        }
    }
    
    func render(location : CLLocation, place : Place = Place()){
        let cordinate = CLLocationCoordinate2D(latitude: location.coordinate.longitude, longitude: location.coordinate.latitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: cordinate, span: span)
        map.setRegion(region,animated: true)
        map.delegate = self
        
        let pin = CustomAnnotation()
        pin.coordinate = cordinate
        pin.place = place
        map.addAnnotation(pin)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "myAnnotation") as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotation")
        } else {
            annotationView?.annotation = annotation
        }
        if let annotation = annotation as? CustomAnnotation {
            annotationView?.pinTintColor = annotation.pinTintColor
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        DispatchQueue.main.async {
            if (self.placeView != nil) || (view.annotation == nil){
                self.placeView.dismiss()
                self.placeText.dismiss()
            }
            let annotation = view.annotation as! CustomAnnotation
            let image = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
            if annotation.place.imgUrl.count > 0{
                image.kf.setImage(with: URL(string: annotation.place.imgUrl))
            }else{
                image.image = UIImage(named: "small_location")
            }
            image.backgroundColor = UIColor(netHex: 0x5AC8FA)
            
            var imgPreferences = EasyTipView.Preferences()
            imgPreferences.drawing.arrowPosition = EasyTipView.ArrowPosition.top
            imgPreferences.drawing.backgroundColor = UIColor.clear
            
            self.placeView = EasyTipView(contentView: image,preferences: imgPreferences)
            self.placeView.show(forView: view, withinSuperview: self.view)

            var txtPreferences = EasyTipView.Preferences()
            txtPreferences.drawing.arrowPosition = EasyTipView.ArrowPosition.bottom
            txtPreferences.drawing.backgroundColor = UIColor(netHex: 0x5AC8FA)

            self.placeText = EasyTipView(text: annotation.place.name, preferences: txtPreferences)
            self.placeText.show(forView: view, withinSuperview: self.view)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if (self.placeView != nil){
            self.placeView.dismiss()
            self.placeText.dismiss()
        }
    }
}
