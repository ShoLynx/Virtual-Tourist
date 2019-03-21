//
//  AppClient.swift
//  Virtual Tourist
//
//  Created by Administrator on 2/17/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class AppClient {
    
    //MARK: APIs and contact URLs
    static var apiKey = "d26903be8565e2dde8b47edd610f600c"
    static var secret = "6d2d350b627a353e"
    
    //create endpoints
    enum Endpoints {
        static let flickrURL = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)"
        
        case getData(String, Int)
        
        var stringValue: String {
            switch self {
                case .getData(let coordinates, let page): return Endpoints.flickrURL + "&sort=interestingness-desc&accuracy=11\(coordinates)&extras=url_n&per_page=30&page=\(page)&format=json&nojsoncallback=1"
            }
        }
        
        var url: URL {
            return URL(string: self.stringValue)!
        }
    }
    
    
    //Global Functions
    
    class func getPhotoData(coordinates: String, page: Int, completion: @escaping(Photos?, Error?) -> Void) {
        let target = Endpoints.getData(coordinates, page).url
        let task = URLSession.shared.dataTask(with: target) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            do {
                let decoder = JSONDecoder()
//                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let responseObject = try decoder.decode(FlickrResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject.photos, nil)
                    PhotoPool.photo = responseObject.photos.photo
                    ForMaxPages.pages = responseObject.photos.pages
                    print(String(data: data, encoding: .utf8)!)
                }
            } catch {
                do {
                    let decoder = JSONDecoder()
                    let errorResponse = try decoder.decode(EResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                        print(String(data: data, encoding: .utf8)!)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                        print(error)
                    }
                }
            }
        }
        task.resume()
    }
    
    class func downloadPhoto(url: URL, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if error == nil {
                if let data = data {
                    completion(data, nil)
                }
            } else {
                completion(nil, error)
                print(error!)
            }
        }
        task.resume()
    }
    
}
