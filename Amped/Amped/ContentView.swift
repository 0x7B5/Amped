//
//  ContentView.swift
//  Amped
//
//  Created by 0x7B5 on 8/8/23.
//

import SwiftUI
import MapKit
import CoreLocation
import FirebaseCore
import PartialSheet

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

struct ContentView: View {
    @State private var ebikeOnlyCount: Int = 0
    @State private var emptyCount: Int = 0
    @State private var lastUpdateTime: Date? = nil
    @State private var initialRegionSet = false
    @StateObject private var locationManager = LocationManager()
    @StateObject private var locationViewModel = LocationViewModel()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    )
    
    @State private var annotations: [StationAnnotation] = []
    @State private var isLoading: Bool = false
    @State private var dataRefreshTimer: Timer? = nil
    @State private var isSettingsSheetVisible: Bool = false
    @State private var showEmptyStations: Bool = true
    @State private var isStationSheetVisible: Bool = false
    @State private var currentStation: Station = Station(stationId: "Null", stationName: "Null", location: Station.Location(lat: 40.7831, lng: -73.9712), totalBikesAvailable: 0, ebikesAvailable: 0, isOffline: true)
    @State private var walkingTime: TimeInterval? = nil
    @State private var isInfoSheetVisible: Bool = false
    
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
                                currentStation = stationAnnotation.station;
                                calculateWalkingTime();
                                isStationSheetVisible = true
                            }
                    }
                }
//                switch stationAnnotation.type {
//                case .empty:
//                    return MapPin(coordinate: stationAnnotation.coordinate, tint: .red)
//                case .ebikeOnly:
//                    return MapPin(coordinate: stationAnnotation.coordinate, tint: .blue)
//                }
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
            VStack {
                Text("""
Ebikes are typically 17 cents/min. Non-ebikes are free for members, up to 45 mins. After that, the pricing is 17 cents/min for all bikes. However, if there are only ebikes at a station, they are free for members (like a non-ebike would be). Furthermore, if you park the bike within the 45 mins at an empty station and rescan it, you can get another free 45mins.\n\nWe built this app to help you find empty stations and ones with only ebikes. If you have any suggestions, feel free to reach out to us.\n
""")
                
                    .font(.body)
                    .fontWeight(.regular)
                HStack {
                    Text("- ")
                    Link("Vlad", destination: URL(string: "https://twitter.com/0x07b5")!)
                    Text("&")
                    Link("Kevin", destination: URL(string: "https://www.linkedin.com/in/kevin-choo-989135147/")!)
                }
            }
            .padding()
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
            VStack {
                ZStack(alignment: .top) {
                    Text(currentStation.stationName)
                        .fontWeight(.bold)
                        .font(.title)
                        .padding(.top)
                        .multilineTextAlignment(.center)
                    HStack {
                        Spacer()
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title)
                            .onTapGesture {
                                isStationSheetVisible = false
                            }
                            .offset(x: -10, y: -20)
                    }
                }
                HStack {
                    VStack {
                        HStack {
                            Image(systemName: "bicycle")
                                .font(.title)
                            Text(String(currentStation.ebikesAvailable))
                                .font(.title)
                        }
                        Text("ebikes")
                            .font(.caption)
                    }
                    Divider()
                        .frame(width: 4)
                        .frame(height: 50)
                        .padding()
                    VStack {
                        HStack {
                            Image(systemName: "figure.walk")
                                .font(.title)
                            Text(walkingTime.map { formatTime(TimeInterval($0))}  ?? "unknown")
                                .font(.title)
                        }
                        Text("minutes")
                            .font(.caption)
                    }
                }
                Button {
                    openDirections()
                } label: {
                    Text("Get Directions").bold()
                }
                .buttonStyle(DirectionsButton())
            }
        }
    }
    
    struct DirectionsButton: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(Rectangle())
                .scaleEffect(configuration.isPressed ? 1.1 : 1)
        }
    }
    
    private func openDirections() {
        let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: currentStation.location.lat, longitude: currentStation.location.lng))
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
                
        destinationItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
    
    private func calculateWalkingTime() {
        locationViewModel.calculateWalkingTime(to: CLLocationCoordinate2D(latitude: currentStation.location.lat, longitude: currentStation.location.lng)) { time in
            walkingTime = time
        }
    }
    private func formatTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute]
        return formatter.string(from: time) ?? ""
    }
    
    func setupDataRefreshTimer() {
        dataRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            // Fetch the data silently
            loadData(silently: true)
        }
    }

    func invalidateDataRefreshTimer() {
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

struct PinIcon: View {
    var numEbikesAvailable: Int
    
    var body: some View {
        if(numEbikesAvailable == 0){
                VStack(spacing: 0){
                    ZStack {
                        Image(systemName: "circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        Text("0")
                            .foregroundColor(.white)
                    }
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                        .offset(x: 0, y: -5)
                }
        } else {
            VStack(spacing: 0) {
                ZStack {
                    Image(systemName: "circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text(String(numEbikesAvailable))
                        .foregroundColor(.white)
                }
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .offset(x: 0, y: -5)
            }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().attachPartialSheetToRoot()
    }
    
}
