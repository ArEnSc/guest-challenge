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


extension MKMapView {
    /// when we call this function, we have already added the annotations to the map, and just want all of them to be displayed.
    func fitAll() {
        var zoomRect            = MKMapRect.null;
        for annotation in annotations {
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect       = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.01, height: 0.01);
            zoomRect            = zoomRect.union(pointRect);
        }
        setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
    }
    
}

class ViewController: UIViewController, MKMapViewDelegate {

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
    
    func showLoadingIndicator() {
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
    
    @objc
    func startButtonPressed() {
        // YYZ to YVR its -3 from that list
        guard let airportPathFinder = self.airportPathFinder else { return }
        
        airportPathFinder.airportPathesBetween(origin: self.airports[1], destination: self.airports[152])
            .then { (airport) in
             self.drawMap(with: airport)
             self.mapView.fitAll()
            }.catch { (error) in
                self.displayErrorMessage(message: error.localizedDescription)
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
        all(service.getAirlines(),service.getRoutes(),service.getAirports())
        .then(on: .main) { (airlines, routes, airports) in
            self.airports = airports
            self.airportPathFinder = AirPortPathFinder(airports: airports, routes: routes)
            self.hideLoadingIndicator()
        }
        
        
        
        
    }

}

