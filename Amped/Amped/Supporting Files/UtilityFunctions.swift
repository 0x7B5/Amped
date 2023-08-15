//
//  UtilityFunctions.swift
//  Amped
//
//  Created by Kevin Choo on 8/15/23.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

public func openDirections(currentStation: Station) {
    let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: currentStation.location.lat, longitude: currentStation.location.lng))
    let destinationItem = MKMapItem(placemark: destinationPlacemark)
            
    destinationItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
}

func calculateWalkingTime(locationManager: CLLocationManager, to destinationCoordinate: CLLocationCoordinate2D, completion: @escaping (TimeInterval?) -> Void) {
    DispatchQueue.global().async {
        guard let userLocation = locationManager.location else {
            completion(nil)
            return
        }
        
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation.coordinate))
        request.destination = destinationItem
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else {
                completion(nil)
                return
            }
            
            completion(route.expectedTravelTime)
        }
    }
}

public func formatTime(_ time: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [.minute]
    return formatter.string(from: time) ?? ""
}

