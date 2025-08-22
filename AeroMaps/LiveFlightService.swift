import SwiftUI
import MapKit
import Foundation
import Combine

// MARK: - Live Flight Data Models
struct LiveFlight: Identifiable, Codable {
    let id = UUID()
    let icao24: String
    let callsign: String?
    let origin: String?
    let destination: String?
    let coordinate: CLLocationCoordinate2D
    let altitude: Double?
    let speed: Double?
    let heading: Double?
    let verticalRate: Double?
    let squawk: String?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case icao24, callsign, origin, destination, coordinate, altitude, speed, heading, verticalRate, squawk, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        icao24 = try container.decode(String.self, forKey: .icao24)
        callsign = try container.decodeIfPresent(String.self, forKey: .callsign)
        origin = try container.decodeIfPresent(String.self, forKey: .origin)
        destination = try container.decodeIfPresent(String.self, forKey: .destination)
        
        // Decode coordinate
        let lat = try container.decode(Double.self, forKey: .coordinate)
        let lon = try container.decode(Double.self, forKey: .coordinate)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        altitude = try container.decodeIfPresent(Double.self, forKey: .altitude)
        speed = try container.decodeIfPresent(Double.self, forKey: .speed)
        heading = try container.decodeIfPresent(Double.self, forKey: .heading)
        verticalRate = try container.decodeIfPresent(Double.self, forKey: .verticalRate)
        squawk = try container.decodeIfPresent(String.self, forKey: .squawk)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(icao24, forKey: .icao24)
        try container.encodeIfPresent(callsign, forKey: .callsign)
        try container.encodeIfPresent(origin, forKey: .origin)
        try container.encodeIfPresent(destination, forKey: .destination)
        try container.encode(coordinate.latitude, forKey: .coordinate)
        try container.encode(coordinate.longitude, forKey: .coordinate)
        try container.encodeIfPresent(altitude, forKey: .altitude)
        try container.encodeIfPresent(speed, forKey: .speed)
        try container.encodeIfPresent(heading, forKey: .heading)
        try container.encodeIfPresent(verticalRate, forKey: .verticalRate)
        try container.encodeIfPresent(squawk, forKey: .squawk)
        try container.encode(timestamp, forKey: .timestamp)
    }
}

// MARK: - Live Flight Service
class LiveFlightService: ObservableObject {
    @Published var flights: [LiveFlight] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // OpenSky Network API (free tier)
    private let baseURL = "https://opensky-network.org/api"
    private let username = "your_username" // Replace with your OpenSky username
    private let password = "your_password" // Replace with your OpenSky password
    
    init() {
        startLiveUpdates()
    }
    
    deinit {
        stopLiveUpdates()
    }
    
    func startLiveUpdates() {
        // Update every 30 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.fetchLiveFlights()
        }
        
        // Initial fetch
        fetchLiveFlights()
    }
    
    func stopLiveUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchLiveFlights() {
        isLoading = true
        error = nil
        
        // For demo purposes, we'll use simulated data
        // In production, you would use the OpenSky API or similar service
        generateSimulatedFlights()
    }
    
    private func generateSimulatedFlights() {
        // Generate realistic flight data around the Bay Area
        let bayAreaFlights = [
            LiveFlight(
                icao24: "A12345",
                callsign: "UAL1234",
                origin: "KSFO",
                destination: "KLAX",
                coordinate: CLLocationCoordinate2D(latitude: 37.5, longitude: -122.2),
                altitude: 35000,
                speed: 450,
                heading: 180,
                verticalRate: 0,
                squawk: "1234",
                timestamp: Date()
            ),
            LiveFlight(
                icao24: "B67890",
                callsign: "SWA5678",
                origin: "KSJC",
                destination: "KLAS",
                coordinate: CLLocationCoordinate2D(latitude: 37.3, longitude: -121.9),
                altitude: 28000,
                speed: 380,
                heading: 120,
                verticalRate: 500,
                squawk: "5678",
                timestamp: Date()
            ),
            LiveFlight(
                icao24: "C11111",
                callsign: "AAL9999",
                origin: "KOAK",
                destination: "KPHX",
                coordinate: CLLocationCoordinate2D(latitude: 37.7, longitude: -122.1),
                altitude: 32000,
                speed: 420,
                heading: 90,
                verticalRate: -200,
                squawk: "9999",
                timestamp: Date()
            ),
            LiveFlight(
                icao24: "D22222",
                callsign: "DAL4444",
                origin: "KSFO",
                destination: "KSEA",
                coordinate: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.4),
                altitude: 38000,
                speed: 480,
                heading: 0,
                verticalRate: 0,
                squawk: "4444",
                timestamp: Date()
            ),
            LiveFlight(
                icao24: "E33333",
                callsign: "JBU7777",
                origin: "KSJC",
                destination: "KJFK",
                coordinate: CLLocationCoordinate2D(latitude: 37.2, longitude: -121.8),
                altitude: 41000,
                speed: 520,
                heading: 60,
                verticalRate: 300,
                squawk: "7777",
                timestamp: Date()
            ),
            LiveFlight(
                icao24: "F44444",
                callsign: "ASA8888",
                origin: "KRNO",
                destination: "KSFO",
                coordinate: CLLocationCoordinate2D(latitude: 38.5, longitude: -121.0),
                altitude: 25000,
                speed: 350,
                heading: 240,
                verticalRate: -400,
                squawk: "8888",
                timestamp: Date()
            ),
            LiveFlight(
                icao24: "G55555",
                callsign: "WJA6666",
                origin: "CYYZ",
                destination: "KSFO",
                coordinate: CLLocationCoordinate2D(latitude: 37.9, longitude: -122.6),
                altitude: 36000,
                speed: 460,
                heading: 200,
                verticalRate: 0,
                squawk: "6666",
                timestamp: Date()
            ),
            LiveFlight(
                icao24: "H66666",
                callsign: "N12345",
                origin: "KSQL",
                destination: "KPAO",
                coordinate: CLLocationCoordinate2D(latitude: 37.4, longitude: -122.0),
                altitude: 3500,
                speed: 120,
                heading: 90,
                verticalRate: 0,
                squawk: "1200",
                timestamp: Date()
            )
        ]
        
        // Update flight positions slightly to simulate movement
        let updatedFlights = bayAreaFlights.map { flight in
            let timeDiff = Date().timeIntervalSince(flight.timestamp)
            let distance = (flight.speed ?? 0) * timeDiff / 3600 // nautical miles
            let bearing = flight.heading ?? 0
            
            let newLat = flight.coordinate.latitude + (distance * cos(bearing * .pi / 180)) / 60
            let newLon = flight.coordinate.longitude + (distance * sin(bearing * .pi / 180)) / (60 * cos(flight.coordinate.latitude * .pi / 180))
            
            return LiveFlight(
                icao24: flight.icao24,
                callsign: flight.callsign,
                origin: flight.origin,
                destination: flight.destination,
                coordinate: CLLocationCoordinate2D(latitude: newLat, longitude: newLon),
                altitude: flight.altitude,
                speed: flight.speed,
                heading: flight.heading,
                verticalRate: flight.verticalRate,
                squawk: flight.squawk,
                timestamp: Date()
            )
        }
        
        DispatchQueue.main.async {
            self.flights = updatedFlights
            self.isLoading = false
        }
    }
    
    // Real API implementation (commented out for demo)
    private func fetchFromOpenSkyAPI() {
        guard let url = URL(string: "\(baseURL)/states/all") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication for OpenSky API
        let authString = "\(username):\(password)"
        if let authData = authString.data(using: .utf8) {
            let base64Auth = authData.base64EncodedString()
            request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: OpenSkyResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                    }
                },
                receiveValue: { response in
                    self.flights = response.states.compactMap { state in
                        guard let lat = state[6] as? Double,
                              let lon = state[5] as? Double,
                              let icao24 = state[0] as? String else { return nil }
                        
                        return LiveFlight(
                            icao24: icao24,
                            callsign: state[1] as? String,
                            origin: state[11] as? String,
                            destination: state[12] as? String,
                            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                            altitude: state[13] as? Double,
                            speed: state[9] as? Double,
                            heading: state[10] as? Double,
                            verticalRate: state[11] as? Double,
                            squawk: state[4] as? String,
                            timestamp: Date()
                        )
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - OpenSky API Response Model
struct OpenSkyResponse: Codable {
    let time: Int
    let states: [[Any]]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        time = try container.decode(Int.self, forKey: .time)
        states = try container.decode([[Any]].self, forKey: .states)
    }
    
    enum CodingKeys: String, CodingKey {
        case time, states
    }
}

// MARK: - Live Flight Annotation View
class LiveFlightAnnotationView: MKAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        image = UIImage(systemName: "airplane.circle.fill")
        tintColor = .systemGreen
        canShowCallout = true
    }
    
    func update(with flight: LiveFlight) {
        // Update annotation appearance based on flight data
        if let altitude = flight.altitude {
            if altitude > 30000 {
                tintColor = .systemBlue // High altitude
            } else if altitude > 10000 {
                tintColor = .systemGreen // Medium altitude
            } else {
                tintColor = .systemOrange // Low altitude
            }
        }
        
        // Add callout information
        let calloutView = LiveFlightCalloutView(flight: flight)
        detailCalloutAccessoryView = calloutView
    }
}

// MARK: - Live Flight Callout View
struct LiveFlightCalloutView: UIViewRepresentable {
    let flight: LiveFlight
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.layer.cornerRadius = 8
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.3
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Flight info
        if let callsign = flight.callsign {
            let callsignLabel = UILabel()
            callsignLabel.text = callsign
            callsignLabel.font = UIFont.boldSystemFont(ofSize: 14)
            stackView.addArrangedSubview(callsignLabel)
        }
        
        // Route info
        if let origin = flight.origin, let destination = flight.destination {
            let routeLabel = UILabel()
            routeLabel.text = "\(origin) → \(destination)"
            routeLabel.font = UIFont.systemFont(ofSize: 12)
            routeLabel.textColor = UIColor.secondaryLabel
            stackView.addArrangedSubview(routeLabel)
        }
        
        // Altitude and speed
        let infoLabel = UILabel()
        var infoText = ""
        if let altitude = flight.altitude {
            infoText += "FL\(Int(altitude/100))"
        }
        if let speed = flight.speed {
            infoText += " • \(Int(speed))kt"
        }
        infoLabel.text = infoText
        infoLabel.font = UIFont.systemFont(ofSize: 12)
        infoLabel.textColor = UIColor.secondaryLabel
        stackView.addArrangedSubview(infoLabel)
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update view if needed
    }
}
