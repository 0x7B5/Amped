//
//  UtilityFunctions.swift
//  Amped
//
//  Created by Kevin Choo on 8/15/23.
//

import Foundation
import SwiftUI

public func openDirections() {
    let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: currentStation.location.lat, longitude: currentStation.location.lng))
    let destinationItem = MKMapItem(placemark: destinationPlacemark)
            
    destinationItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
}

public func calculateWalkingTime() {
    locationViewModel.calculateWalkingTime(to: CLLocationCoordinate2D(latitude: currentStation.location.lat, longitude: currentStation.location.lng)) { time in
        walkingTime = time
    }
}
public func formatTime(_ time: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [.minute]
    return formatter.string(from: time) ?? ""
}

public func setupDataRefreshTimer() {
    dataRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
        // Fetch the data silently
        loadData(silently: true)
    }
}

public func invalidateDataRefreshTimer() {
    dataRefreshTimer?.invalidate()
    dataRefreshTimer = nil
}

func loadData(silently: Bool = false) {
    print("Loading data")
    
    DispatchQueue.global().async { // Perform the task on a background thread
        
        if !silently {
            DispatchQueue.main.async {
                isLoading = true
            }
        }
        
        let api = CitibikeAPI()
        
        api.fetchStations { stations in
            
            var categories = api.categorizeStations(stations: stations)
            
            let annotationsToAdd = categories.emptyStations.map { StationAnnotation(coordinate: $0.location.toCLLocationCoordinate2D(), type: .empty, station: $0) }
            + categories.ebikeOnlyStations.map { StationAnnotation(coordinate: $0.location.toCLLocationCoordinate2D(), type: .ebikeOnly, station: $0)  }
            
            DispatchQueue.main.async { // Switching to main thread for UI updates
                if !silently {
                    isLoading = false
                }
                
                annotations = annotationsToAdd
                ebikeOnlyCount = categories.ebikeOnlyStations.count
                emptyCount = categories.emptyStations.count
                self.lastUpdateTime = Date()
                
                // Uncomment if you need this:
                // if let userLocation = locationManager.location {
                //     updateRegion(to: userLocation.coordinate)
                // }
            }
        }
    }
}


func updateRegion(to coordinate: CLLocationCoordinate2D) {
    region.center = coordinate
    region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
}
