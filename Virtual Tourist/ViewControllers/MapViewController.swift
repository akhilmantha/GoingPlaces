//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by akhil mantha on 23/08/18.
//  Copyright © 2018 akhil mantha. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var label: UILabel!
    
    //MARK: = Variables
    var annotation: MKPointAnnotation? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
        label.isHidden = true
        
        if let pins = loadPins() {
            showPins(pins)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotoDisplayViewController {
            guard let pin = sender as? Pin else {
                return
            }
            let controller = segue.destination as! PhotoDisplayViewController
            controller.pin = pin
        }
    }
    
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        
        let location = sender.location(in: mapView)
        let coord = mapView.convert(location, toCoordinateFrom: mapView)
        
        if sender.state == .began {
            
            annotation = MKPointAnnotation()
            annotation!.coordinate = coord
            
            mapView.addAnnotation(annotation!)
        } else if sender.state == .changed {
            annotation!.coordinate = coord
        } else if sender.state == .ended {
            
            _ = Pin(
                latitude: String(annotation!.coordinate.latitude),
                longitude: String(annotation!.coordinate.longitude),
                context: DataController.shared().context
            )
            save()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        label.isHidden = !editing
    }
    
    private func loadPins() -> [Pin]? {
        var pins: [Pin]?
        do {
            try pins = DataController.shared().fetchPins(entityName: Pin.name)
        } catch {
            showErrorInfo(title: "Error", message: "Error while fetching Pin locations: \(error)")
        }
        return pins
    }
    
    private func loadPin(latitude: String, longitude: String) -> Pin? {
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)
        var pin: Pin?
        do{
            try pin = DataController.shared().fetchPin(predicate, entityName: Pin.name)
        } catch {
            showErrorInfo(title: "Error", message: "Error while fetching location: \(error)")
        }
        return pin
    }
    
    func showPins(_ pins: [Pin]) {
        for pin in pins where pin.latitude != nil && pin.longitude != nil {
            let annotation = MKPointAnnotation()
            let latitude = Double(pin.latitude!)!
            let longitude = Double(pin.longitude!)!
            annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
}

extension MapViewController{
    // MARK: Using MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
        
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view!.canShowCallout = false
            view!.animatesDrop = true
        } else {
            view!.annotation = annotation
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl){
        if control == view.rightCalloutAccessoryView {
            self.showErrorInfo(title: "Error", message: "No link defined.")
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else {
            return
        }
        
        mapView.deselectAnnotation(annotation, animated: true)
        let latitude = String(annotation.coordinate.latitude)
        let longitude = String(annotation.coordinate.longitude)
        if let pin = loadPin(latitude: latitude, longitude: longitude) {
            if isEditing {
                mapView.removeAnnotation(annotation)
                DataController.shared().context.delete(pin)
                save()
                return
            }
            
            performSegue(withIdentifier: "showPhotos", sender: pin)
        }
    }
}


