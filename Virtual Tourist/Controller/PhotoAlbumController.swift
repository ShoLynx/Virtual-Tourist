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
        let sortDescriptor = NSSortDescriptor(key: "imageURL", ascending: false)
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
        
        //Setup default behavior and delegates
        noImagesLabel.isHidden = true
        newCollectionButton.isEnabled = false
        photoCollection.delegate = self
        photoCollection.dataSource = self
        setCollectionFormat()
        setupFetchedResultsController()
        
        //Start getting photo data from Flickr
        AppClient.getPhotoData(coordinates: pin.coordinateString!, page: 1, completion: handlePhotoDataResponse(photos:error:))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Zoom in on the selected pin in the map view and ensure the album has the latest info
        setPin(coordinates: selectedPinCoordinates!)
        photoCollection.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //empty PhotoPool and related arrays
        PhotoPool.photo = []
        photoArray = []
        batchDeleteRequest()
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
        batchDeleteRequest()
        setupFetchedResultsController()
        //Run getPhotoData with completion handler handlePhotoDataResponse(Run downloadPhoto)
        AppClient.getPhotoData(coordinates: pin.coordinateString!, page: photoPage, completion: handlePhotoDataResponse)
    }
    
    @IBAction func backToMap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func setCollectionFormat() {
        let space: CGFloat = 2.0
        let size = self.view.frame.size
        let dWidth = (size.width - (space)) / 2.0
        let dHeight = (size.height - (space)) / 5.0
        
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
            photoArray.append(flickrPhoto)
        }
        
        DispatchQueue.main.async {
            try? self.dataController.viewContext.save()
            self.photoCollection.reloadData()
        }
    }
    
    func handlePhotoDataResponse (photos: Photos?, error: Error?) {
        if photos != nil {
            //Create local variables for PhotoPool.photo and ForMaxPages.pages
            imagePool = photos!.photo
            maxPages = ForMaxPages.pages
            getImageURL()
            newCollectionButton.isEnabled = true
        } else {
            //The noImagesLabel should be enough to convey if there is a problem with downloads
            print(error!)
            noImagesLabel.isHidden = false
        }
    }
    
    fileprivate func batchDeleteRequest() {
        //empty fetchedResultsController and clear the photoCollection
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FlickrPhoto")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try dataController.viewContext.execute(batchDeleteRequest)
            photoCollection.reloadData()
        } catch {
            fatalError("The delete process could not be completed. \(error.localizedDescription)")
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
        //Display placeholder image
        cell.pinImage.image = UIImage(named: "imagePlaceholder")
        let cellImage = photoArray[indexPath.row]
        //Get imageURLs from Core Data
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

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Create a loop to search the FRC for imageData similar to the one selected, save and then delete selected from FRC.
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        for photo in photoArray {
            if photo.imageData == photoToDelete.imageData{
                dataController.viewContext.delete(photoToDelete)
                try? dataController.viewContext.save()
            }
        }
        //Delete from local array
        photoArray.remove(at: indexPath.row)
        //Delete from collection view
        collectionView.deleteItems(at: [indexPath])
    }

}
