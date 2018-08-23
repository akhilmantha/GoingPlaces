//
//  PhotoDisplayViewController.swift
//  Virtual Tourist
//
//  Created by akhil mantha on 23/08/18.
//  Copyright © 2018 akhil mantha. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class PhotoDisplayViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    //MARK: - Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout?
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var status: UILabel!
    
    //MARK: - Variables
    
    var selectedIndexes = [IndexPath]()
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var totalPages: Int? = nil
    
    var presentingAlert = false
    var pin: Pin?
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateFlowLayout(view.frame.size)
        mapView.delegate = self
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        
        updateStatus("")
        
        guard let pin = pin else {
            return
        }
        showOnTheMap(pin)
        setupFetchedResultControllerWith(pin)
        
        if let photos = pin.photos, photos.count == 0 {
            fetchPhotosFromAPI(pin)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateFlowLayout(size)
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        for photos in fetchedResultsController.fetchedObjects! {
            DataController.shared().context.delete(photos)
        }
        save()
        fetchPhotosFromAPI(pin!)
    }
    
    private func setupFetchedResultControllerWith(_ pin: Pin) {
        
        let fetchrequest = NSFetchRequest<Photo>(entityName: Photo.name)
        fetchrequest.sortDescriptors = []
        fetchrequest.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchrequest, managedObjectContext: DataController.shared().context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("\(#function) Error performing initial fetch: \(error)")
        }
    }
    
    private func fetchPhotosFromAPI(_ pin: Pin) {
        let latitude = Double(pin.latitude!)!
        let longitude = Double(pin.longitude!)!
        
        activityIndicator.startAnimating()
        self.updateStatus("Fetching photos ..")
        
        Client.shared().searchBy(latitude: latitude, longitude: longitude, totalPages: totalPages) { (photosParsed, error) in
            self.performUIUpdatesOnMain {
                self.activityIndicator.stopAnimating()
                self.status.text = ""
            }
            if let photosParsed = photosParsed {
                self.totalPages = photosParsed.photos.pages
                let totalPhotos = photosParsed.photos.photo.count
                self.storePhotos(photosParsed.photos.photo, forPin: pin)
                if totalPhotos == 0 {
                    self.updateStatus("No photos found for this location")
                }
            } else if let error = error {
                self.showErrorInfo(title: "Error", message: error.localizedDescription)
                self.updateStatus("Something went wrong, please try again")
            }
        }
    }
    
    private func updateStatus( _ text: String) {
        self.performUIUpdatesOnMain {
            self.status.text = text
        }
    }
    
    private func storePhotos(_ photos: [PhotoParser], forPin: Pin) {
        func showErrorMessage(msg: String) {
            showErrorInfo(title: "Error", message: msg)
        }
        
        for photo in photos {
            performUIUpdatesOnMain {
                if let url = photo.url {
                    _ = Photo(title: photo.title, imageUrl: url, forPin: forPin, context: DataController.shared().context)
                    self.save()
                }
            }
        }
    }
    
    private func showOnTheMap(_ pin: Pin) {
        
        let latitude = Double(pin.latitude!)!
        let longitude = Double(pin.longitude!)!
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coord
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        mapView.setCenter(coord, animated: true)
    }
    
    private func loadPhotos(using pin: Pin) -> [Photo]? {
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        var photos: [Photo]?
        do {
            try photos = DataController.shared().fetchPhotos(predicate, entityName: Photo.name)
        } catch {
            showErrorInfo(title: "Error", message: "Error while loading Photos from disk: \(error)")
        }
        return photos
    }
    
    private func updateFlowLayout(_ withSize: CGSize) {
        
        let landscape = withSize.width > withSize.height
        
        let space: CGFloat = landscape ? 5 : 3
        let items: CGFloat = landscape ? 2 : 3
        
        let dimension = (withSize.width - ((items + 1) * space)) / items
        
        flowLayout?.minimumInteritemSpacing = space
        flowLayout?.minimumLineSpacing = space
        flowLayout?.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout?.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            newCollection.setTitle("Remove Selected", for: .normal)
        } else {
            newCollection.setTitle("New Collection", for: .normal)
        }
    }
}

//MARK: - Using Map View Delegate

extension PhotoDisplayViewController {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view!.canShowCallout = false
        } else {
            view!.annotation = annotation
        }
        return view
    }
}




