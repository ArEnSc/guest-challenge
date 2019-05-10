//
//  ViewController.swift
//  RoutesApp
//
//  Created by Michael Chung on 5/7/19.
//  Copyright © 2019 Michael Chung. All rights reserved.
//

import UIKit
import MapKit
import Promises

class ViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate {
    
    enum Error: String, Swift.Error, LocalizedError {
        case toFieldEmpty = "Destination Field is Empty"
        case fromFieldEmpty = "Origin Field is Empty"
    
        var errorDescription: String? {
            return self.rawValue
        }
    }

    @IBOutlet weak var startSearchButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var fromAirport: UITextField!
    @IBOutlet weak var toAirport: UITextField!
    
    var airports:[Airport] = []
    
    var service:DataService = DataService.shared
    var airportPathFinder:AirPortPathFinder?
    
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    
    let regionRadius: CLLocationDistance = 1000
    var currentPolyline:MKPolyline?

    var lastFrameSize:CGRect?
    
    func showLoadingIndicator() {
        self.activityIndicator.isHidden = false
        
       self.activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
       self.activityIndicator.stopAnimating()
    }
    
    func initializeUI() {
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.activityIndicator.hidesWhenStopped = true

        view.addSubview(activityIndicator)
        
        self.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.activityIndicator.heightAnchor.constraint(equalToConstant: 25).isActive = true
        self.activityIndicator.widthAnchor.constraint(equalToConstant: 25).isActive = true
        self.activityIndicator.layer.zPosition = 1
        
        self.mapView.delegate = self
       
        self.startSearchButton.addTarget(self,
                                action: #selector(startButtonPressed),
                                for: .touchUpInside)
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc
    func keyBoardWillShow(notification: Notification) {
        //handle appearing of keyboard here
        // You can use the keyboard duration key also possibly the easing curve of that to animate the view out of the way. ;D
        let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        self.lastFrameSize = frame
       
        UIView.animate(withDuration: 0.7) {
            self.view.frame = CGRect(x: self.view.frame.origin.x, y: 0.0, width: self.view.frame.width, height: self.view.frame.height)
        }
        
        UIView.animate(withDuration: 0.7) {
            self.view.frame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y - self.lastFrameSize!.height, width: self.view.frame.width, height: self.view.frame.height)
        }
    }
    
    @objc
    func keyBoardWillHide(notification: Notification) {
        //handle dismiss of keyboard here
        UIView.animate(withDuration: 0.7) {
            self.view.frame = CGRect(x: self.view.frame.origin.x, y: 0.0, width: self.view.frame.width, height: self.view.frame.height)
        }
    }
    
    
    func drawMap(with airports:([Airport])) {
        let coordinates = self.locationCoordinates(from: airports)
        
        for (airport,coordinate) in zip(airports, coordinates) {
            let pointAnnotation = MKPointAnnotation()
            pointAnnotation.title = "\(airport.city) \(airport.name) \(airport.IATAThree)"
            pointAnnotation.coordinate = coordinate
            self.mapView.addAnnotation(pointAnnotation)
            
            let overlays = MKCircle(center: coordinate, radius: 10.0)
            self.mapView.addOverlay(overlays)
        }
        
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        self.mapView.addOverlay(polyline)
    }
    
    func removeMapRenderings() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.removeOverlays(self.mapView.overlays)
    }
    
    func displayErrorMessage(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    func pullInputFields() -> Promise<(String,String)> {
        return Promise({ (fullfill, reject) in
            guard var fromInput = self.fromAirport.text,
                fromInput.isEmpty == false else {
                reject(Error.fromFieldEmpty)
                return
            }
            guard var toInput = self.toAirport.text,
                      toInput.isEmpty == false else {
                reject(Error.toFieldEmpty)
                return
            }
            
            fromInput = fromInput.replacingOccurrences(of: " ", with: "")
            toInput = toInput.replacingOccurrences(of: " ", with: "")
            
            fullfill((fromInput,toInput))
        })
    }

    @objc
    func startButtonPressed() {
            
        self.showLoadingIndicator()
        self.view.endEditing(true)
        self.startSearchButton.isEnabled = false
        
        guard let airportPathFinder = self.airportPathFinder else { return }
        removeMapRenderings()
        
        pullInputFields().then { (arg0) -> Promise<[Airport]>  in
            let (fromAirport, toAirport) = arg0
            return all([airportPathFinder.airportExists(name: fromAirport),airportPathFinder.airportExists(name: toAirport)])
        }.then { (airports) in
            return airportPathFinder.airportPathesBetween(origin: airports[0], destination: airports[1])
        }.then { (airports) in
            self.drawMap(with: airports)
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }.catch { (error) in
            
            self.displayErrorMessage(message: error.localizedDescription)
        }.always {
            self.hideLoadingIndicator()
            self.startSearchButton.isEnabled = true
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black
            renderer.strokeColor = UIColor.black
            renderer.lineWidth = 1.0
            return renderer
        }
        
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.black
            renderer.lineWidth = 1
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        else {
            let id = "annotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier:id)
            
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.canShowCallout = true
            return annotationView
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func locationCoordinates(from airports:[Airport]) -> [CLLocationCoordinate2D] {
        let result = airports.map { (airport) -> CLLocationCoordinate2D in
            return CLLocationCoordinate2D(latitude: airport.lat, longitude: airport.long)
        }
        return result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeUI()
        // Do any additional setup after loading the view, typically from a nib.
        
        // loading display loading label block user
        self.showLoadingIndicator()
        self.startSearchButton.isEnabled = false
        
        all(service.getAirlines(),service.getRoutes(),service.getAirports())
        .then(on: .main) { (airlines, routes, airports) in
            self.airports = airports
            self.airportPathFinder = AirPortPathFinder(airports: airports, routes: routes)
            self.hideLoadingIndicator()
            self.startSearchButton.isEnabled = true
        }
        
    }


}

