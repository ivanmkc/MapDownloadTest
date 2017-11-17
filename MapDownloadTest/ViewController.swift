//
//  ViewController.swift
//  MapDownloadTest
//
//  Created by Ivan Cheung on 2017-11-17.
//  Copyright © 2017 Tripverse Co. All rights reserved.
//

import UIKit
import Mapbox
import MapKit

struct Constants
{
    static let MAP_DOWNLOAD_RADIUS_IN_METERS: Double = 10
    static let DEFAULT_ACTIVITY_ZOOM_LEVEL: Double = 15
    static let DEFAULT_DISCOVER_ZOOM_LEVEL: Double = 15
}

extension CLLocationCoordinate2D {
    func translate(using latitudinalMeters: CLLocationDistance, longitudinalMeters: CLLocationDistance) -> CLLocationCoordinate2D {
        let region = MKCoordinateRegionMakeWithDistance(self, latitudinalMeters, longitudinalMeters)
        return CLLocationCoordinate2D(latitude: latitude + region.span.latitudeDelta, longitude: longitude + region.span.longitudeDelta)
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //NOTE: Set your own Mapbox token
        
        // Setup offline pack notification handlers.
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        
        //Coordinate for Eiffel Tower
        let coordinates = CLLocationCoordinate2D.init(latitude: 48.8584, longitude: 2.2945)
        
        // Do any additional setup after loading the view, typically from a nib.
        let activityBounds = MGLCoordinateBounds.init(sw: coordinates.translate(using: -Constants.MAP_DOWNLOAD_RADIUS_IN_METERS, longitudinalMeters: -Constants.MAP_DOWNLOAD_RADIUS_IN_METERS), ne: coordinates.translate(using: Constants.MAP_DOWNLOAD_RADIUS_IN_METERS, longitudinalMeters: Constants.MAP_DOWNLOAD_RADIUS_IN_METERS))
        
        let zoomLevelMin: Double
        let zoomLevelMax: Double
        
        if (Constants.DEFAULT_DISCOVER_ZOOM_LEVEL < Constants.DEFAULT_ACTIVITY_ZOOM_LEVEL)
        {
            zoomLevelMin = Constants.DEFAULT_DISCOVER_ZOOM_LEVEL
            zoomLevelMax = Constants.DEFAULT_ACTIVITY_ZOOM_LEVEL
        }
        else
        {
            zoomLevelMax = Constants.DEFAULT_DISCOVER_ZOOM_LEVEL
            zoomLevelMin = Constants.DEFAULT_ACTIVITY_ZOOM_LEVEL
        }
        
        let region = MGLTilePyramidOfflineRegion.init(styleURL: nil, bounds: activityBounds, fromZoomLevel: zoomLevelMin, toZoomLevel: zoomLevelMax)
        
        MGLOfflineStorage.shared().addPack(for: region, withContext: "ASDF".data(using: String.Encoding.utf8)!, completionHandler:
            { (pack, error) in
                if let error = error {
                    return
                }
                else if let pack = pack {
                    pack.resume()
                }
        })
    }
    
    // MARK: - MGLOfflinePack notification handlers
    
    @objc func offlinePackProgressDidChange(notification: NSNotification) {
        // Get the offline pack this notification is regarding,
        // and the associated user info for the pack; in this case, `name = My Offline Pack`
        if let pack = notification.object as? MGLOfflinePack {
            let progress = pack.progress
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected
            
            // Calculate current progress percentage.
            let progressPercentage = Float(completedResources) / Float(expectedResources)
            
            // If this pack has finished, print its size and resource count.
            if completedResources == expectedResources {
                let byteCount = ByteCountFormatter.string(fromByteCount: Int64(pack.progress.countOfBytesCompleted), countStyle: ByteCountFormatter.CountStyle.memory)
                print("Offline pack completed: \(byteCount), \(completedResources) resources")
            } else {
                // Otherwise, print download/verification progress.
                print("Offline pack has \(completedResources) of \(expectedResources) resources — \(progressPercentage * 100)%.")
            }
        }
    }
}
