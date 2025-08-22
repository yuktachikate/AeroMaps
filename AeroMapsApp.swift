import SwiftUI
import MapKit
import CoreLocation

// MARK: - App Entry
@main
struct AeroMapsApp: App {
    @StateObject private var loc = LocationManager()
    @StateObject private var weatherService = WeatherService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loc)
                .environmentObject(weatherService)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Enhanced Models
struct Airport: Identifiable, Hashable {
    let id = UUID()
    let icao: String
    let name: String
    let city: String
    let state: String
    let coordinate: CLLocationCoordinate2D
    let elevation: Int
    let runways: [Runway]
    let frequencies: [Frequency]
    let services: [String]
    
    static func == (lhs: Airport, rhs: Airport) -> Bool {
        lhs.icao == rhs.icao
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(icao)
    }
}

struct Runway: Identifiable, Codable {
    let id = UUID()
    let designation: String
    let length: Int
    let width: Int
    let surface: String
    let lighted: Bool
}

struct Frequency: Identifiable, Codable {
    let id = UUID()
    let type: String
    let frequency: String
    let description: String
}

struct WeatherData: Codable {
    let metar: String?
    let taf: String?
    let wind: WindData?
    let visibility: Double?
    let ceiling: Int?
    let temperature: Double?
    let pressure: Double?
}

// MARK: - Flight Analysis Model
struct FlightAnalysis {
    let callsign: String
    let origin: String
    let destination: String
    let altitude: Double
    let speed: Double
    let heading: Double
    let verticalRate: Double
    let squawk: String
    let distance: Double
    let eta: Date?
    let fuelRemaining: Double?
    let weather: String?
}

struct WindData: Codable {
    let direction: Int
    let speed: Int
    let gust: Int?
}

enum MapStyle: String, CaseIterable, Equatable {
    case standard = "Standard"
    case hybrid = "Hybrid"
    case satellite = "Satellite"
}

enum LayerKind: String, CaseIterable, Identifiable {
    case traffic, radar, airspace, terrain, tfr, notams, fuel, weather, plates, ffmRisk
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .radar: return "Radar"
        case .airspace: return "Airspace"
        case .traffic: return "Traffic"
        case .terrain: return "Terrain"
        case .tfr: return "TFR"
        case .notams: return "NOTAMs"
        case .fuel: return "Fuel"
        case .weather: return "Weather"
        case .plates: return "Plates"
        case .ffmRisk: return "FFM Risk"
        }
    }
    
    var systemImage: String {
        switch self {
        case .radar: return "wave.3.right.circle.fill"
        case .airspace: return "shield.lefthalf.filled"
        case .traffic: return "airplane.circle.fill"
        case .terrain: return "mountain.2.fill"
        case .tfr: return "exclamationmark.triangle.fill"
        case .notams: return "list.bullet.rectangle.fill"
        case .fuel: return "fuelpump.fill"
        case .weather: return "cloud.rain.fill"
        case .plates: return "doc.richtext.fill"
        case .ffmRisk: return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .radar: return .blue
        case .airspace: return .cyan
        case .traffic: return .green
        case .terrain: return .brown
        case .tfr: return .red
        case .notams: return .orange
        case .fuel: return .yellow
        case .weather: return .blue
        case .plates: return .purple
        case .ffmRisk: return .pink
        }
    }
}

enum FlightMode: String, CaseIterable {
    case plan = "Plan"
    case fly = "Fly"
    case review = "Review"
    
    var icon: String {
        switch self {
        case .plan: return "paperplane"
        case .fly: return "airplane.circle.fill"
        case .review: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .plan: return .blue
        case .fly: return .green
        case .review: return .orange
        }
    }
}

struct RoutePlan {
    var waypoints: [Airport] = []
    var altitudeFT: Int = 8000
    var cruiseKTAS: Double = 120
    var fuelBurn: Double = 8.5 // gallons per hour
    var departureTime: Date = Date()
    
    var totalDistance: Double {
        guard waypoints.count >= 2 else { return 0 }
        var sum: Double = 0
        for i in 0..<(waypoints.count - 1) {
            sum += haversineNM(waypoints[i].coordinate, waypoints[i+1].coordinate)
        }
        return sum
    }
    
    var estimatedTime: TimeInterval {
        guard cruiseKTAS > 0 else { return 0 }
        return (totalDistance / cruiseKTAS) * 3600 // seconds
    }
    
    var fuelRequired: Double {
        return (estimatedTime / 3600) * fuelBurn
    }
    
    private func haversineNM(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let Rnm = 3440.065
        func rad(_ d: Double) -> Double { d * .pi / 180 }
        
        let dLat = rad(b.latitude - a.latitude)
        let dLon = rad(b.longitude - a.longitude)
        let la1 = rad(a.latitude), la2 = rad(b.latitude)
        
        let h = sin(dLat/2)*sin(dLat/2) + cos(la1)*cos(la2)*sin(dLon/2)*sin(dLon/2)
        let c = 2 * atan2(sqrt(h), sqrt(1-h))
        return Rnm * c
    }
}

// MARK: - Enhanced App State
final class MapState: ObservableObject {
    @Published var camera = MKMapCamera(
        lookingAtCenter: CLLocationCoordinate2D(latitude: 37.6213, longitude: -122.3790),
        fromDistance: 100_000,
        pitch: 0,
        heading: 0
    )
    @Published var searchText: String = ""
    @Published var route = RoutePlan()
    @Published var activeLayers: Set<LayerKind> = [.traffic, .airspace, .terrain, .weather]
    @Published var mode: FlightMode = .plan
    @Published var showSheet: Bool = true
    @Published var mapStyle: MapStyle = .standard
    @Published var selectedAirport: Airport? = nil
    @Published var selectedFlight: FlightAnalysis? = nil
    @Published var showingAirportDetail = false
    @Published var showingFlightPlanner = false
    @Published var showingWeatherPanel = false
    @Published var riskOverlays: [MKTileOverlay] = []
    @Published var ffmAdvice: String = ""
    @Published var legRisks: [FFMResponse.LegRisk] = []
    @Published var computedPolyline: MKPolyline? = nil
    
    // References for analysis
    var locationManager: LocationManager?
    var weatherService: WeatherService?
    
    // Enhanced airport database
    let airports: [String: Airport] = [
        "KSFO": Airport(
            icao: "KSFO",
            name: "San Francisco International",
            city: "San Francisco",
            state: "CA",
            coordinate: .init(latitude: 37.6213, longitude: -122.3790),
            elevation: 13,
            runways: [
                Runway(designation: "10L/28R", length: 11870, width: 200, surface: "Asphalt", lighted: true),
                Runway(designation: "10R/28L", length: 11481, width: 200, surface: "Asphalt", lighted: true),
                Runway(designation: "01L/19R", length: 7500, width: 200, surface: "Asphalt", lighted: true),
                Runway(designation: "01R/19L", length: 8800, width: 200, surface: "Asphalt", lighted: true)
            ],
            frequencies: [
                Frequency(type: "ATIS", frequency: "118.1", description: "Automated Terminal Information"),
                Frequency(type: "Ground", frequency: "121.9", description: "Ground Control"),
                Frequency(type: "Tower", frequency: "120.5", description: "Tower Control"),
                Frequency(type: "Approach", frequency: "135.9", description: "NorCal Approach")
            ],
            services: ["Fuel", "Maintenance", "Rental Cars", "Hotel Shuttle", "Restaurant"]
        ),
        "KSJC": Airport(
            icao: "KSJC",
            name: "San Jose International",
            city: "San Jose",
            state: "CA",
            coordinate: .init(latitude: 37.3639, longitude: -121.9289),
            elevation: 62,
            runways: [
                Runway(designation: "11L/29R", length: 11000, width: 150, surface: "Asphalt", lighted: true),
                Runway(designation: "11R/29L", length: 11000, width: 150, surface: "Asphalt", lighted: true)
            ],
            frequencies: [
                Frequency(type: "ATIS", frequency: "118.3", description: "Automated Terminal Information"),
                Frequency(type: "Ground", frequency: "121.7", description: "Ground Control"),
                Frequency(type: "Tower", frequency: "119.7", description: "Tower Control"),
                Frequency(type: "Approach", frequency: "125.7", description: "NorCal Approach")
            ],
            services: ["Fuel", "Maintenance", "Rental Cars", "Hotel Shuttle", "Restaurant"]
        ),
        "KRNO": Airport(
            icao: "KRNO",
            name: "Reno/Tahoe International",
            city: "Reno",
            state: "NV",
            coordinate: .init(latitude: 39.4986, longitude: -119.7681),
            elevation: 4415,
            runways: [
                Runway(designation: "07/25", length: 11002, width: 150, surface: "Asphalt", lighted: true),
                Runway(designation: "16R/34L", length: 9000, width: 150, surface: "Asphalt", lighted: true),
                Runway(designation: "16L/34R", length: 6000, width: 100, surface: "Asphalt", lighted: true)
            ],
            frequencies: [
                Frequency(type: "ATIS", frequency: "118.1", description: "Automated Terminal Information"),
                Frequency(type: "Ground", frequency: "121.8", description: "Ground Control"),
                Frequency(type: "Tower", frequency: "118.5", description: "Tower Control"),
                Frequency(type: "Approach", frequency: "125.3", description: "NorCal Approach")
            ],
            services: ["Fuel", "Maintenance", "Rental Cars", "Hotel Shuttle", "Restaurant", "Casino Shuttle"]
        ),
        "KSQL": Airport(
            icao: "KSQL",
            name: "San Carlos",
            city: "San Carlos",
            state: "CA",
            coordinate: .init(latitude: 37.5119, longitude: -122.2495),
            elevation: 5,
            runways: [
                Runway(designation: "12/30", length: 2600, width: 75, surface: "Asphalt", lighted: true)
            ],
            frequencies: [
                Frequency(type: "CTAF", frequency: "122.8", description: "Common Traffic Advisory Frequency"),
                Frequency(type: "Ground", frequency: "121.9", description: "Ground Control"),
                Frequency(type: "Tower", frequency: "120.5", description: "Tower Control")
            ],
            services: ["Fuel", "Maintenance", "Flight School", "Restaurant"]
        ),
        "KOAK": Airport(
            icao: "KOAK",
            name: "Oakland International",
            city: "Oakland",
            state: "CA",
            coordinate: .init(latitude: 37.7214, longitude: -122.2208),
            elevation: 9,
            runways: [
                Runway(designation: "11/29", length: 10500, width: 200, surface: "Asphalt", lighted: true),
                Runway(designation: "15/33", length: 6000, width: 150, surface: "Asphalt", lighted: true)
            ],
            frequencies: [
                Frequency(type: "ATIS", frequency: "118.2", description: "Automated Terminal Information"),
                Frequency(type: "Ground", frequency: "121.8", description: "Ground Control"),
                Frequency(type: "Tower", frequency: "120.3", description: "Tower Control"),
                Frequency(type: "Approach", frequency: "125.7", description: "NorCal Approach")
            ],
            services: ["Fuel", "Maintenance", "Rental Cars", "Hotel Shuttle", "Restaurant", "BART"]
        )
    ]
    
    func toggle(_ kind: LayerKind) {
        if activeLayers.contains(kind) {
            activeLayers.remove(kind)
        } else {
            activeLayers.insert(kind)
        }
        
        if kind == .terrain {
            mapStyle = activeLayers.contains(.terrain) ? .hybrid : .standard
        }
    }
    

    
    func addWaypoint(_ coord: CLLocationCoordinate2D, named: String? = nil) {
        let name = named ?? "WPT \(route.waypoints.count + 1)"
        let airport = Airport(
            icao: name,
            name: name,
            city: "",
            state: "",
            coordinate: coord,
            elevation: 0,
            runways: [],
            frequencies: [],
            services: []
        )
        route.waypoints.append(airport)
    }
    
    func clearRoute() {
        route.waypoints.removeAll()
    }
    
    func parseSearch() {
        let searchTerm = searchText.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it's an airport ICAO code
        if let airport = airports[searchTerm] {
            // Move camera to airport location
            withAnimation(.easeInOut(duration: 1.0)) {
                camera = MKMapCamera(
                    lookingAtCenter: airport.coordinate,
                    fromDistance: 50000,
                    pitch: 0,
                    heading: 0
                )
            }
            
            // Select the airport
            selectedAirport = airport
            showingAirportDetail = true
            searchText = ""
            return
        }
        
        // Check if it's a city name
        for (_, airport) in airports {
            if airport.city.uppercased().contains(searchTerm) || 
               airport.name.uppercased().contains(searchTerm) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    camera = MKMapCamera(
                        lookingAtCenter: airport.coordinate,
                        fromDistance: 50000,
                        pitch: 0,
                        heading: 0
                    )
                }
                selectedAirport = airport
                showingAirportDetail = true
                searchText = ""
                return
            }
        }
        
        // If not found, show a simple alert or just clear the search
        searchText = ""
    }
    
    func zoomToRoute() {
        guard route.waypoints.count >= 1 else { return }
        
        let lats = route.waypoints.map { $0.coordinate.latitude }
        let lons = route.waypoints.map { $0.coordinate.longitude }
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat+maxLat)/2,
            longitude: (minLon+maxLon)/2
        )
        let span = max(maxLat - minLat, maxLon - minLon)
        let distance = max(50_000, span * 111_000 * 1.8)
        
        withAnimation(.easeInOut(duration: 1.0)) {
            camera = MKMapCamera(
                lookingAtCenter: center,
                fromDistance: distance,
                pitch: 0,
                heading: 0
            )
        }
    }
}

// MARK: - FFM Planning
extension MapState {
    @MainActor
    func computeFFMPlan() async {
        guard route.waypoints.count >= 2 else { return }
        // Safety envelope and clamping
        var clampedKTAS = max(80, min(220, route.cruiseKTAS))
        var clampedFuel = max(6.0, min(18.0, route.fuelBurn))
        // Enforce minimum altitude as a proxy for MEF
        route.altitudeFT = max(2000, route.altitudeFT)
        // Build request
        let request = FFMRequest(
            aircraft: .init(type: "GA", trueAirspeedKTAS: clampedKTAS, fuelBurnGPH: clampedFuel),
            route: route.waypoints.map { .init(lat: $0.coordinate.latitude, lon: $0.coordinate.longitude) },
            policy: .init(reserveMinutes: 45, enforceMEF: true)
        )
        let client = FFMClient()
        do {
            let response = try await client.plan(request: request, useMock: false)
            // Update overlays and state
            let poly = response.polyline.toPolyline()
            self.computedPolyline = poly
            self.legRisks = response.legRisks
            self.ffmAdvice = response.advisory
            // Build risk tile overlays
            self.riskOverlays = response.riskTileTemplates.map { template in
                let overlay = MKTileOverlay(urlTemplate: template)
                overlay.canReplaceMapContent = false
                return overlay
            }
        } catch {
            self.ffmAdvice = "FFM planning failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Weather Service
class WeatherService: ObservableObject {
    @Published var currentWeather: [String: WeatherData] = [:]
    
    func fetchWeather(for airport: Airport) {
        // Simulated weather data - in real app, this would call aviation weather APIs
        let weather = WeatherData(
            metar: "KSFO 152253Z 24028G35KT 10SM FEW030 BKN250 18/08 A3001",
            taf: "KSFO 152200Z 1522/1624 24025G35KT P6SM FEW030 BKN250 FM160600 24020G30KT P6SM SCT030 BKN250",
            wind: WindData(direction: 240, speed: 28, gust: 35),
            visibility: 10.0,
            ceiling: 3000,
            temperature: 18.0,
            pressure: 30.01
        )
        
        DispatchQueue.main.async {
            self.currentWeather[airport.icao] = weather
        }
    }
}

// MARK: - Location Manager
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var heading: CLHeading?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 5
    }
    
    func request() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
}
