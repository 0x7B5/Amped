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
    
    @State private var ebikeOnlyCount: Int = 0
    @State private var emptyCount: Int = 0
    
    @State private var walkingTime: TimeInterval? = nil
    @State private var isDataLoadingInProgress: Bool = false
    private let uiUpdateSemaphore = DispatchSemaphore(value: 1)

    
    @State private var annotations: [StationAnnotation] = []
    @State private var isSettingsSheetVisible: Bool = false
    @State private var isStationSheetVisible: Bool = false
    @State private var currentStation: Station = Station(stationId: "Null", stationName: "Null", location: Station.Location(lat: 40.7831, lng: -73.9712), totalBikesAvailable: 0, ebikesAvailable: 0, isOffline: true)
    @State private var isInfoSheetVisible: Bool = false
    @State private var showEmptyStations: Bool = true
    
    @State private var lastUpdateTime: Date? = nil

    @State private var initialRegionSet = false
    @State private var dataRefreshTimer: Timer? = nil
    
    @State private var isLoading: Bool = false
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )

    var lastUpdateTimeString: String {
        guard let lastUpdate = lastUpdateTime else { return "00:00" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: lastUpdate)
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: annotations) { stationAnnotation -> MapAnnotation in
                MapAnnotation(coordinate: stationAnnotation.coordinate){
                    if(stationAnnotation.station.ebikesAvailable > 0 || (showEmptyStations && stationAnnotation.station.ebikesAvailable == 0)) {
                        PinIcon(numEbikesAvailable: stationAnnotation.station.ebikesAvailable)
                            .onTapGesture {
                                handleTap(for: stationAnnotation.station)
                            }
                    }
                }
            }
            .onAppear(perform: {
                loadData()
                dataRefreshTimer = setupDataRefreshTimer()
            })
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
                            SmallPinIcon()
                                .foregroundColor(.blue)
                                .offset(y: 3)
                            Text("Ebikes Only: \(ebikeOnlyCount)")
                                .font(.footnote)
                                .foregroundColor(Color.black)
                        }
                        HStack(spacing: 8) {
                            SmallPinIcon()
                                .foregroundColor(.red)
                                .offset(y: 3)
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
        .onDisappear {
            closePartialSheet()
        }
        .partialSheet(isPresented: $isSettingsSheetVisible) {
            Settings(showEmptyStations: $showEmptyStations)
        }
        .onDisappear {
            closePartialSheet()
        }
        .partialSheet(isPresented: $isStationSheetVisible) {
            StationInfo(currentStation: currentStation, walkingTime: $walkingTime, isStationSheetVisible: $isStationSheetVisible)
        }
        .onDisappear {
            closePartialSheet()
        }
    }
    
    func handleTap(for station: Station) {
       currentStation = station
       calculateWalkingTime(locationManager: locationManager.locationManager, to: CLLocationCoordinate2D(latitude: currentStation.location.lat, longitude: currentStation.location.lng)) { time in
          walkingTime = time ?? 0
        isStationSheetVisible = true
       }
    }
    
    func loadData(silently: Bool = false) {
        let startTime = Date()
        let minimumLoadingDisplayDuration: TimeInterval = 1.0 // Set this to your desired minimum time in seconds

        // If it's not a silent load, we start by setting the loading indicator
        if !silently {
            isLoading = true
        }

        // Ensure loadData isn't concurrently being accessed
        uiUpdateSemaphore.wait()

        DispatchQueue.global().async {
            let api = CitibikeAPI()
            api.fetchStations { stations in
                var categories = api.categorizeStations(stations: stations)
                let annotationsToAdd = categories.emptyStations.map { StationAnnotation(coordinate: $0.location.toCLLocationCoordinate2D(), type: .empty, station: $0) }
                + categories.ebikeOnlyStations.map { StationAnnotation(coordinate: $0.location.toCLLocationCoordinate2D(), type: .ebikeOnly, station: $0) }

                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed < minimumLoadingDisplayDuration {
                    let remaining = minimumLoadingDisplayDuration - elapsed
                    DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
                        self.updateUIAfterLoading(annotationsToAdd: annotationsToAdd, categories: categories, silently: silently)
                        self.uiUpdateSemaphore.signal()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.updateUIAfterLoading(annotationsToAdd: annotationsToAdd, categories: categories, silently: silently)
                        self.uiUpdateSemaphore.signal()
                    }
                }
            }
        }
    }
    
    func closePartialSheet() {
        // Try to decrement the semaphore. If the current value is zero, this will block until the semaphore is incremented.
        uiUpdateSemaphore.wait()

        // You can include other cleanup tasks here if needed.

        // Release the semaphore.
        uiUpdateSemaphore.signal()
    }
    
    private func updateUIAfterLoading(annotationsToAdd: [StationAnnotation], categories: (emptyStations: [Station], ebikeOnlyStations: [Station]), silently: Bool) {
        if !silently {
            isLoading = false
        }
        annotations = annotationsToAdd
        ebikeOnlyCount = categories.ebikeOnlyStations.count
        emptyCount = categories.emptyStations.count
        self.lastUpdateTime = Date()
    }
    
    func updateRegion(to coordinate: CLLocationCoordinate2D) {
        region.center = coordinate
        region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    }
    
    public func setupDataRefreshTimer() -> Timer {
        var dataRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            // Fetch the data silently
            loadData(silently: true)
        }
        return dataRefreshTimer
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
