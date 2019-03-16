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
    
    //var pins = [MKPointAnnotation]()
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var selectedPinCoordinates: CLLocationCoordinate2D?
    var selectedAnnotation: MKPointAnnotation?

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
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
        
        for pin in fetchedResultsController.fetchedObjects ?? [] {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            travelMap.addAnnotation(annotation)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // To be added:
        // - Right Navigation Button becomes an Edit button
        // - Left Navigation Button becomes 'Delete All' button
        // - Tapping a pin in Edit mode produces Delete confirmation alert.  No dismisses the alert, Yes deletes the individual pin AND removes its info from the array (could probably add 'if editing' to mapView didSelectAt)
        // - Tapping Delete all produces Delete All confirmation alert.  No dismisses the alert, Yes deletes all pins and empties the pin array
    }

    func handlePhotoDataResponse (photos: [Photo]?, error: Error?) {
        if photos != nil {
            travelMap.isUserInteractionEnabled = true
            activityIndicator.stopAnimating()
            performSegue(withIdentifier: "goToPinPhotos", sender: self)
        } else {
            travelMap.isUserInteractionEnabled = true
            activityIndicator.stopAnimating()
            showErrorAlert(message: error?.localizedDescription ?? "")
        }
    }
    
    func showErrorAlert(message: String) {
        let alertVC = UIAlertController(title: "Problem Getting Data", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
    
    func showDeleteAlert() {
        let alertVC = UIAlertController(title: "Are You Sure?", message: "Do you want to remove this pin?", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
            //Enter cancel function here.
            alertVC.dismiss(animated: true, completion: nil)
        }))
        alertVC.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            //Enter deleteAnnotation functionality here
        }))
    }
    
    func showDeleteAllAlert() {
        let alertVC = UIAlertController(title: "Are You Sure?", message: "Do you want to remove all of your pins?", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
            //Enter cancel function here.
            alertVC.dismiss(animated: true, completion: nil)
        }))
        alertVC.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            //Enter deleteAll functionality here
        }))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let newPinned2D = selectedPinCoordinates
        let destinationVC = segue.destination as! PhotoAlbumController
        destinationVC.selectedPinCoordinates = newPinned2D
        destinationVC.dataController = dataController
        destinationVC.imagePool = PhotoPool.photo
    }
    
    @objc func addAnnotation(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: travelMap)
        let newCoordinates = travelMap.convert(touchPoint, toCoordinateFrom: travelMap)
        let pin = Pin(context: dataController.viewContext)
        
        pin.latitude = newCoordinates.latitude
        pin.longitude = newCoordinates.longitude
        pin.coordinateString = "&lat=\(pin.latitude)&lon=\(pin.longitude)"
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        travelMap.addAnnotation(annotation)
        try? dataController.viewContext.save()
    }
    
    @objc func deleteAnnotation() {
        //Enter deleteAnnotation function here
    }
    
    @IBAction func pinchAction(pinch: UIPinchGestureRecognizer) {
        var pinchScale = pinchGesture.scale
        pinchScale = round(pinchScale * 1000) / 1000.0
    }
    
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
        activityIndicator.startAnimating()
        self.selectedAnnotation = view.annotation as? MKPointAnnotation
        let pin = Pin(context: dataController.viewContext)
        let pinned2D = selectedAnnotation!.coordinate
        pin.latitude = pinned2D.latitude
        pin.longitude = pinned2D.longitude
        selectedPinCoordinates = pinned2D
        pin.coordinateString = "&lat=\(pin.latitude)&lon=\(pin.longitude)"
        AppClient.getPhotoData(coordinates: pin.coordinateString!, completion: handlePhotoDataResponse(photos:error:))
    }

}

