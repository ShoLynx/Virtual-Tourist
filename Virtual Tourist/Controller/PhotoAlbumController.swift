//
//  PhotoAlbumController.swift
//  Virtual Tourist
//
//  Created by Administrator on 2/17/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    // MARK: Setup
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var zoomedMap: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    
    var pin: Pin!
    var selectedPinCoordinates: CLLocationCoordinate2D?
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<FlickrPhoto>!
    var maxPages: Int?
    var imagePool: [Photo] = []
    var photoArray: [FlickrPhoto] = []
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<FlickrPhoto> = FlickrPhoto.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "pin = %@", pin)
        let sortDescriptor = NSSortDescriptor(key: "imageURL", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pin")
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
        
        //Setup default behavior and delegates
        noImagesLabel.isHidden = true
        newCollectionButton.isEnabled = false
        photoCollection.delegate = self
        photoCollection.dataSource = self
        setCollectionFormat()
        setupFetchedResultsController()
        
        photoArray = fetchedResultsController.fetchedObjects ?? []
        
        //Start getting photo data from Flickr
        if photoArray.isEmpty {
            AppClient.getPhotoData(coordinates: pin.coordinateString!, page: 1, completion: handlePhotoDataResponse(photos:pages:error:))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        //Zoom in on the selected pin in the map view and ensure the album has the latest info
        setPin(coordinates: selectedPinCoordinates!)
        photoCollection.reloadData()
    }
    
    // MARK: Class-specific Functions
    
    @IBAction func newCollectionTapped(_ sender: Any) {
        //set variable for a random Int between 1 and the max number of pages from download
        let photoPage = Int.random(in: 1...(maxPages ?? 1))
        //disable NewCollectionButton
        self.newCollectionButton.isEnabled = false
        //empty PhotoPool.photo and reset FRC
        PhotoPool.photo = []
        photoArray = []
        emptyPhotoArray()
        setupFetchedResultsController()
        //Run getPhotoData with completion handler handlePhotoDataResponse
        AppClient.getPhotoData(coordinates: pin.coordinateString!, page: photoPage, completion: handlePhotoDataResponse(photos:pages:error:))
    }
    
    @IBAction func backToMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func setCollectionFormat() {
        let space: CGFloat = 4.0
        let size = self.view.frame.size
        let dWidth = (size.width - (space)) / 2.0
        let dHeight = (size.height - (space)) / 4.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dWidth, height: dHeight)
    }
    
    func setPin(coordinates: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        let latitudeMeters: CLLocationDistance = 100000
        let longitudeMeters: CLLocationDistance = 100000
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: latitudeMeters, longitudinalMeters: longitudeMeters)
        annotation.coordinate = coordinates
        zoomedMap.addAnnotation(annotation)
        zoomedMap.setRegion(region, animated: true)
    }
    
    func getImageURL () {
        //Get the image URL from each photo object for Core Data and AppClient.downloadPhoto
        for photo in imagePool {
            let flickrPhoto = FlickrPhoto(context: dataController.viewContext)
            flickrPhoto.imageURL = photo.url_n
            flickrPhoto.pin = pin
            photoArray.append(flickrPhoto)
        }
        
        DispatchQueue.main.async {
            try? self.dataController.viewContext.save()
            self.photoCollection.reloadData()
        }
    }
    
    func handlePhotoDataResponse (photos: Photos?, pages: Int?, error: Error?) {
        if photos != nil {
            //Create local variables for PhotoPool.photo and ForMaxPages.pages
            imagePool = photos!.photo
            maxPages = min(pages!, 4000/30)
            getImageURL()
            newCollectionButton.isEnabled = true
        } else {
            //The noImagesLabel should be enough to convey when there is a problem with downloads
            print(error!)
            noImagesLabel.isHidden = false
        }
    }
    
    func emptyPhotoArray() {
        for photo in photoArray {
            dataController.viewContext.delete(photo)
            try? self.dataController.viewContext.save()
        }
    }
    
    //This provides an alert for users to confirm deleting a photo from the collection.  Add to didSelectItem at
    func deleteAlert() {
        
    }

    // MARK: Collection View Setup
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionCell", for: indexPath) as! PhotoAlbumCollectionCell
        let cellImage = photoArray[indexPath.row]
        
        //Display placeholder image if there is no image data available
        if cellImage.imageData != nil {
            cell.pinImage.image = UIImage(data: cellImage.imageData!)
            cell.activityIndicator.stopAnimating()
            cell.activityIndicator.hidesWhenStopped = true
            newCollectionButton.isEnabled = true
        } else {
            cell.pinImage.image = UIImage(named: "imagePlaceholder")
            
            //Get imageURLs from Core Data
            if cellImage.imageURL != nil {
                let url = URL(string: cellImage.imageURL!)!
                DispatchQueue.main.async {
                    //Activate loading circle
                    cell.activityIndicator.startAnimating()
                    cell.activityIndicator.hidesWhenStopped = true
                }
                
                AppClient.downloadPhoto(url: url) { (data, error) in
                    if error == nil {
                        if let data = data {
                            DispatchQueue.main.async {
                                //Set imageData value for Core Data and save
                                cellImage.imageData = data
                                cellImage.pin = self.pin
                                try? self.dataController.viewContext.save()
                                //Set downloaded image to replace the cell's image
                                cell.pinImage.image = UIImage(data: data)
                                cell.setNeedsLayout()
                                cell.activityIndicator.stopAnimating()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            print(error!)
                        }
                    }
                }
            } else {
                cell.pinImage.image = UIImage(named: "imagePlaceholder")
                cell.activityIndicator.stopAnimating()
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Delete the selected photo and save updates to Core Data
        let photoToDelete = photoArray[indexPath.row]
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        
        //Delete from local array
        photoArray.remove(at: indexPath.row)
        //Delete from collection view
        collectionView.deleteItems(at: [indexPath])
    }

}
