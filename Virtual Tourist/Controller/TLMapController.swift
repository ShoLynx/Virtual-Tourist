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


class TLMapController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
//    PinchGesture method obtained from https://stackoverflow.com/questions/36978190/ios-swift-cannot-get-pinch-to-work
//    HoldGesture method obtained from https://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift
    
    //var pins = [MKPointAnnotation]()
    var mapPins: [Pin] = []
    var dataController: DataController!
    var selectedPinCoordinates: CLLocationCoordinate2D?
    var selectedAnnotation: MKPointAnnotation?

    var holdGesture = UILongPressGestureRecognizer()
    var pinchGesture = UIPinchGestureRecognizer()
    
    @IBOutlet weak var travelMap: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "coordinateString", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            mapPins = result
            travelMap.reloadInputViews()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            //enter mapView didSelect MKAnnotationView At with delete function
            func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
                self.selectedAnnotation = view.annotation as? MKPointAnnotation
                let alertVC = UIAlertController(title: "Are You Sure?", message: "Do you want to delete this pin?", preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                    //Enter cancel function here.
                    alertVC.dismiss(animated: true, completion: nil)
                }))
                alertVC.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                    //Enter delete functionality here
                    mapView.removeAnnotation(self.selectedAnnotation!)
                    //Need to remove from pins array
                }))
            }
        }
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
    
    func showDeleteAllAlert() {
        let alertVC = UIAlertController(title: "Are You Sure?", message: "Do you want to clear the map of pins?", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
            //Enter cancel function here.
            alertVC.dismiss(animated: true, completion: nil)
        }))
        alertVC.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            //Enter deleteAll functionality here
            //use pins.removeAll function
        }))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let newPinned2D = selectedPinCoordinates
        let destinationVC = segue.destination as! PhotoAlbumController
        destinationVC.selectedPinCoordinates = newPinned2D
    }
    
    @objc func addAnnotation(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: travelMap)
        let newCoordinates = travelMap.convert(touchPoint, toCoordinateFrom: travelMap)
        let pinPoint = Pin(context: dataController.viewContext)
        
        pinPoint.latitude = newCoordinates.latitude
        pinPoint.longitude = newCoordinates.longitude
        pinPoint.coordinateString = "&lat=\(pinPoint.latitude)&lon=\(pinPoint.longitude)"
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pinPoint.latitude, longitude: pinPoint.longitude)
        travelMap.addAnnotation(annotation)
        try? dataController.viewContext.save()
        mapPins.append(pinPoint)
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
        let pinned2D = selectedAnnotation!.coordinate
        selectedPinCoordinates = pinned2D
        let latitude = pinned2D.latitude
        let longitude = pinned2D.longitude
        let coordinateString = "&lat=\(latitude)&lon=\(longitude)"
        AppClient.getPhotoData(coordinates: coordinateString, completion: handlePhotoDataResponse(photos:error:))
    }

}

