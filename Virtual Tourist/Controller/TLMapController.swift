//
//  TLMapController.swift
//  Virtual Tourist
//
//  Created by Administrator on 2/16/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import UIKit
import Foundation
import MapKit
import CoreData


class TLMapController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
//    PinchGesture method obtained from https://stackoverflow.com/questions/36978190/ios-swift-cannot-get-pinch-to-work
//    HoldGesture method obtained from https://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift
    
    // MARK: Setup
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var selectedPinCoordinates: CLLocationCoordinate2D?
    var selectedAnnotation: MKPointAnnotation?
    var pins: [Pin] = []
    var selectedPin: Pin!
    var imagePool: [Photo] = []
    var photoArray: [FlickrPhoto] = []

    var holdGesture = UILongPressGestureRecognizer()
    var pinchGesture = UIPinchGestureRecognizer()
    
    @IBOutlet weak var travelMap: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "coordinateString", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup dataController
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
        //Assign delegates and set rules for default behavior
        navigationItem.rightBarButtonItem = editButtonItem
        travelMap.delegate = self
        activityIndicator.stopAnimating()
        activityIndicator.hidesWhenStopped = true
        
        //List gestures here
        holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
        travelMap.addGestureRecognizer(holdGesture)
        holdGesture.minimumPressDuration = 1.0
        
        pinchGesture.delegate = self
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(pinch:)))
        travelMap.addGestureRecognizer(pinchGesture)
        
        setupFetchedResultsController()
        
        //Load existing data onto the map
        for pin in fetchedResultsController.fetchedObjects ?? [] {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            travelMap.addAnnotation(annotation)
            pins.append(pin)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Re-enable FRC after PhotoAlbumController is dismissed
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //Disable FRC when PhotoAlbumController is visible
        fetchedResultsController = nil
    }
    
    // MARK: Class-specific Functions
    
    @IBAction func pinchAction(pinch: UIPinchGestureRecognizer) {
        var pinchScale = pinchGesture.scale
        pinchScale = round(pinchScale * 1000) / 1000.0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! PhotoAlbumController
        
        //Send data to the PhotoAlbumController to ensure information is ready for use
        destinationVC.selectedPinCoordinates = selectedPinCoordinates
        destinationVC.dataController = dataController
        destinationVC.pin = selectedPin
    }
    
    @objc func addAnnotation(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != .began {
            return
        }
        
        //Automatically gets coordinates from dropped pin
        let touchPoint = gestureRecognizer.location(in: travelMap)
        let newCoordinates = travelMap.convert(touchPoint, toCoordinateFrom: travelMap)
        let pin = Pin(context: dataController.viewContext)
        
        //Create the pin object
        pin.latitude = newCoordinates.latitude
        pin.longitude = newCoordinates.longitude
        pin.coordinateString = "&lat=\(pin.latitude)&lon=\(pin.longitude)"
        
        //Setup the annotation, save pin to Core Data and add it to the array
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        travelMap.addAnnotation(annotation)
        try? dataController.viewContext.save()
        pins.append(pin)
        
        travelMap.reloadInputViews()
    }
    
    // MARK: MapView Setup
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "annotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.tintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.selectedAnnotation = view.annotation as? MKPointAnnotation
        let pinned2D = selectedAnnotation!.coordinate
        selectedPinCoordinates = pinned2D
        setupFetchedResultsController()
        pins = fetchedResultsController.fetchedObjects ?? []
        for pin in pins {
            if pin.latitude == pinned2D.latitude && pin.longitude == pinned2D.longitude {
                selectedPin = pin
                performSegue(withIdentifier: "goToPinPhotos", sender: self)
                mapView.deselectAnnotation(view.annotation, animated: true)
                break
            }
        }
    }

}

