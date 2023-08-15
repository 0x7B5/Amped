//
//  StationMapView.swift
//  Amped
//
//  Created by Kevin Choo on 8/14/23.
//

import SwiftUI
import MapKit
import PartialSheet

struct StationMapView: View {
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: annotations) { stationAnnotation -> MapAnnotation in
                MapAnnotation(coordinate: stationAnnotation.coordinate){
                    if(stationAnnotation.station.ebikesAvailable > 0 || (showEmptyStations && stationAnnotation.station.ebikesAvailable == 0)) {
                        PinIcon(numEbikesAvailable: stationAnnotation.station.ebikesAvailable)
                            .onTapGesture {
                                currentStation = stationAnnotation.station;
                                calculateWalkingTime();
                                isStationSheetVisible = true
                            }
                    }
                }
            }
            .onAppear(perform: {
                loadData()
                setupDataRefreshTimer()
            })
            .onDisappear(perform: invalidateDataRefreshTimer)
            .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(true)
                
                VStack {
                    ProgressView()
                    Text("Loading...")
                }
                .padding()
                .foregroundColor(Color.black)
                .background(Color.white.opacity(1.0))
                .cornerRadius(10)
            }
            
            VStack {
                HStack {
                    // Refresh Button
                    Button(action: {
                        loadData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.95))
                    )
                    .padding(.leading, 16)
                    
                    Spacer()
                    Button(action: { isInfoSheetVisible = true }) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(red: 235/255, green: 31/255, blue: 42/255))
                            .padding(.trailing, 16)
                    }
                    
                }
                .padding(.top, 16)
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                            Text("Ebikes Only: \(ebikeOnlyCount)")
                                .font(.footnote)
                                .foregroundColor(Color.black)
                        }
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            Text("Empty Docks: \(emptyCount)")
                                .font(.footnote)
                                .foregroundColor(Color.black)
                        }
                        Text("Last updated: \(lastUpdateTimeString)")
                            .font(.footnote)
                            .foregroundColor(Color(.darkGray))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.95))
                    )
                    .padding(.leading, 16)
                    
                    Spacer()
                    VStack(spacing: 16) {
                        Button(action: {
                            if let userLocation = locationManager.location {
                                updateRegion(to: userLocation.coordinate)
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.95))
                                    .frame(width: 50, height: 50) // Square frame
                                
                                Image(systemName: "location")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(Color.black)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        Button(action: {
                            isSettingsSheetVisible = true
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.95))
                                    .frame(width: 50, height: 50) // Square frame
                                
                                Image(systemName: "slider.horizontal.3")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(Color.black)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    .padding(.trailing, 16)
                }
                .padding(.bottom, 30)
            }
        }
        .onReceive(locationManager.$location) { location in
            if !initialRegionSet, let location = location {
                updateRegion(to: location.coordinate)
                initialRegionSet = true
            }
        }
        .partialSheet(isPresented: $isInfoSheetVisible) {
            AppInfo()
        }
        .partialSheet(isPresented: $isSettingsSheetVisible) {
            VStack {
                Text("Settings")
                    .font(.headline)
                    .padding(.top)
                
                Toggle("Show Empty Stations", isOn: $showEmptyStations)
                    .padding()
                
            }
            .padding(.horizontal)
        }
        .partialSheet(isPresented: $isStationSheetVisible) {
            StationInfo(currentStation: currentStation)
        }
    }
}

class LocationViewModel: ObservableObject {
private var locationManager = CLLocationManager()
    
func calculateWalkingTime(to destinationCoordinate: CLLocationCoordinate2D, completion: @escaping (TimeInterval?) -> Void) {
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

struct StationAnnotation: Identifiable {
var id = UUID()
var coordinate: CLLocationCoordinate2D
var type: StationType
var station: Station
var isSheetOpen = false
var walkingTime: TimeInterval? = nil

    enum StationType {
        case empty
        case ebikeOnly
    }
}

extension Station.Location {
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
