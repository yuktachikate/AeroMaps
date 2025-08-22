import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var mapState = MapState()
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var weatherService: WeatherService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Tab (Home)
            MapTabView(mapState: mapState)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(0)
            
            // Flights Tab
            FlightsTabView(mapState: mapState)
                .tabItem {
                    Image(systemName: "airplane.circle.fill")
                    Text("Flights")
                }
                .tag(1)
            
            // Library Tab
            LibraryTabView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Library")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .onAppear {
            locationManager.request()
            // Set references for analysis
            mapState.locationManager = locationManager
            mapState.weatherService = weatherService
        }
    }
}

// MARK: - Map Tab View
struct MapTabView: View {
    @ObservedObject var mapState: MapState
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var weatherService: WeatherService
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Main Map View
                MapView(mapState: mapState)
                    .ignoresSafeArea()
                
                // Top Controls
                VStack(spacing: 0) {
                    // Status Bar
                    StatusBar(mapState: mapState)
                        .padding(.top, 8)
                    
                    // Search Bar
                    SearchBar(
                        text: $mapState.searchText,
                        onSearch: { mapState.parseSearch() }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                // Layer Controls
                VStack {
                    Spacer()
                    LayerControls(mapState: mapState)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 140)
                }
                
                // Floating Action Buttons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButtons(mapState: mapState)
                            .padding(.trailing, 16)
                            .padding(.bottom, 140)
                    }
                }
                
                                // Bottom Sheet
                BottomSheet(mapState: mapState)
                
                // Annotation Bar for Analysis
                VStack {
                    Spacer()
                    if mapState.selectedAirport != nil {
                        AnnotationBarView(mapState: mapState)
                    }
                }
                
            }
            .navigationTitle("AeroMaps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Settings/Profile action
                    }) {
                        Image(systemName: "person.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $mapState.showingAirportDetail) {
            if let airport = mapState.selectedAirport {
                AirportDetailView(airport: airport, weatherService: weatherService)
            }
        }
        .sheet(isPresented: $mapState.showingFlightPlanner) {
            FlightPlannerView(mapState: mapState)
        }
        .sheet(isPresented: $mapState.showingWeatherPanel) {
            WeatherPanelView(weatherService: weatherService)
        }
    }
}

// MARK: - Flights Tab View
struct FlightsTabView: View {
    @ObservedObject var mapState: MapState
    
    var body: some View {
        NavigationView {
            List {
                Section("Live Traffic") {
                    HStack {
                        Image(systemName: "airplane.circle.fill")
                            .foregroundColor(.green)
                        Text("UAL1234: KSFO → KLAX")
                            .font(.headline)
                        Spacer()
                        Text("FL350")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Image(systemName: "airplane.circle.fill")
                            .foregroundColor(.green)
                        Text("SWA5678: KSJC → KLAS")
                            .font(.headline)
                        Spacer()
                        Text("FL280")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Image(systemName: "airplane.circle.fill")
                            .foregroundColor(.green)
                        Text("AAL9999: KOAK → KPHX")
                            .font(.headline)
                        Spacer()
                        Text("FL320")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Image(systemName: "airplane.circle.fill")
                            .foregroundColor(.green)
                        Text("DAL4444: KSFO → KSEA")
                            .font(.headline)
                        Spacer()
                        Text("FL380")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Section("Recent Flights") {
                    ForEach(1...5, id: \.self) { index in
                        FlightRowView(
                            origin: "KSFO",
                            destination: "KSJC",
                            date: "Today",
                            time: "14:30"
                        )
                    }
                }
                
                Section("Planned Flights") {
                    if mapState.route.waypoints.count >= 2 {
                        FlightRowView(
                            origin: mapState.route.waypoints.first?.icao ?? "",
                            destination: mapState.route.waypoints.last?.icao ?? "",
                            date: "Tomorrow",
                            time: "09:00"
                        )
                    } else {
                        Text("No planned flights")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Flights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Flight") {
                        mapState.showingFlightPlanner = true
                    }
                }
            }
        }
        .sheet(isPresented: $mapState.showingFlightPlanner) {
            FlightPlannerView(mapState: mapState)
        }
    }
}

// MARK: - Library Tab View
struct LibraryTabView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Documents") {
                    NavigationLink("POH & Manuals", destination: Text("POH & Manuals"))
                    NavigationLink("Checklists", destination: Text("Checklists"))
                    NavigationLink("SOPs", destination: Text("SOPs"))
                }
                
                Section("Charts & Plates") {
                    NavigationLink("Approach Plates", destination: Text("Approach Plates"))
                    NavigationLink("Airport Diagrams", destination: Text("Airport Diagrams"))
                    NavigationLink("Sectional Charts", destination: Text("Sectional Charts"))
                }
                
                Section("Downloads") {
                    NavigationLink("Downloaded Charts", destination: Text("Downloaded Charts"))
                    NavigationLink("Offline Data", destination: Text("Offline Data"))
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        // Settings action
                    }
                }
            }
        }
    }
}

// MARK: - Flight Row View
struct FlightRowView: View {
    let origin: String
    let destination: String
    let date: String
    let time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(origin) → \(destination)")
                    .font(.headline)
                Text("\(date) at \(time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}



// MARK: - Map View
struct MapView: UIViewRepresentable {
    @ObservedObject var mapState: MapState
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.mapType = mapState.mapStyle == .hybrid ? .hybrid : .standard
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update camera
        mapView.setCamera(mapState.camera, animated: true)
        
        // Update map type
        mapView.mapType = mapState.mapStyle == .hybrid ? .hybrid : .standard
        
        // Clear existing annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add route waypoints
        for waypoint in mapState.route.waypoints {
            let annotation = MKPointAnnotation()
            annotation.coordinate = waypoint.coordinate
            annotation.title = waypoint.icao
            annotation.subtitle = waypoint.name
            mapView.addAnnotation(annotation)
        }
        
        // Add route line (prefer FFM computed polyline when available)
        if let ffmPoly = mapState.computedPolyline {
            mapView.addOverlay(ffmPoly)
        } else if mapState.route.waypoints.count >= 2 {
            let coordinates = mapState.route.waypoints.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
        }
        
        // Add demo overlays
        if mapState.activeLayers.contains(.airspace) {
            addDemoAirspace(mapView)
        }
        
        if mapState.activeLayers.contains(.tfr) {
            addDemoTFRs(mapView)
        }
        
        // Add airport annotations
        addAirportAnnotations(mapView)
        
        // Add live flight data (simulated)
        if mapState.activeLayers.contains(.traffic) {
            addSimulatedFlights(mapView)
        }

        // Add FFM risk tile overlays
        if mapState.activeLayers.contains(.ffmRisk) {
            for overlay in mapState.riskOverlays {
                mapView.addOverlay(overlay, level: .aboveLabels)
            }
        }
    }
    
    private func addDemoAirspace(_ mapView: MKMapView) {
        let airspaceCoordinates = [
            CLLocationCoordinate2D(latitude: 37.2, longitude: -122.6),
            CLLocationCoordinate2D(latitude: 37.2, longitude: -122.05),
            CLLocationCoordinate2D(latitude: 37.55, longitude: -122.05),
            CLLocationCoordinate2D(latitude: 37.55, longitude: -122.6)
        ]
        
        let polygon = MKPolygon(coordinates: airspaceCoordinates, count: airspaceCoordinates.count)
        mapView.addOverlay(polygon)
    }
    
    private func addDemoTFRs(_ mapView: MKMapView) {
        let tfrCenter = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let circle = MKCircle(center: tfrCenter, radius: 15000) // 15km radius
        mapView.addOverlay(circle)
    }
    
    private func addAirportAnnotations(_ mapView: MKMapView) {
        // Remove existing airport annotations
        let existingAirportAnnotations = mapView.annotations.filter { annotation in
            guard let title = annotation.title else { return false }
            return mapState.airports.keys.contains(title ?? "")
        }
        mapView.removeAnnotations(existingAirportAnnotations)
        
        // Add airport annotations from the database
        for (_, airport) in mapState.airports {
            let annotation = MKPointAnnotation()
            annotation.coordinate = airport.coordinate
            annotation.title = airport.icao
            annotation.subtitle = "\(airport.name) - \(airport.city), \(airport.state)"
            mapView.addAnnotation(annotation)
        }
    }
    
    private func addSimulatedFlights(_ mapView: MKMapView) {
        // Remove existing flight annotations
        let existingAnnotations = mapView.annotations.filter { $0.title == "Flight" }
        mapView.removeAnnotations(existingAnnotations)
        
        // Add simulated flight annotations
        let simulatedFlights = [
            (CLLocationCoordinate2D(latitude: 37.5, longitude: -122.2), "UAL1234", "KSFO", "KLAX"),
            (CLLocationCoordinate2D(latitude: 37.3, longitude: -121.9), "SWA5678", "KSJC", "KLAS"),
            (CLLocationCoordinate2D(latitude: 37.7, longitude: -122.1), "AAL9999", "KOAK", "KPHX"),
            (CLLocationCoordinate2D(latitude: 37.8, longitude: -122.4), "DAL4444", "KSFO", "KSEA"),
            (CLLocationCoordinate2D(latitude: 37.2, longitude: -121.8), "JBU7777", "KSJC", "KJFK")
        ]
        
        for (coordinate, callsign, origin, destination) in simulatedFlights {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Flight"
            annotation.subtitle = "\(callsign): \(origin) → \(destination)"
            mapView.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            parent.mapState.addWaypoint(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tile = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(tileOverlay: tile)
            } else if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            } else if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.systemCyan.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.systemCyan.withAlphaComponent(0.6)
                renderer.lineWidth = 2
                return renderer
            } else if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.1)
                renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.6)
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
            
            // Handle flight annotations
            if annotation.title == "Flight" {
                let identifier = "FlightAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.markerTintColor = .systemGreen
                    markerView.glyphText = "✈"
                }
                
                return annotationView
            }
            
            // Handle airport annotations
            if let title = annotation.title, parent.mapState.airports.keys.contains(title ?? "") {
                let identifier = "AirportAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.markerTintColor = .systemOrange
                    markerView.glyphText = "🏬"
                }
                
                return annotationView
            }
            
            // Handle waypoint annotations (route planning)
            let identifier = "WaypointAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = .systemBlue
                markerView.glyphText = "📍"
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation else { return }
            
            // Handle flight annotations
            if annotation.title == "Flight" {
                // For now, just print the flight info
                print("Selected flight: \(annotation.subtitle ?? "Unknown")")
                return
            }
            
            // Handle airport annotations
            guard let icao = annotation.title,
                  let airport = parent.mapState.airports[icao ?? ""] else { return }
            
            parent.mapState.selectedAirport = airport
            parent.mapState.showingAirportDetail = true
        }
    }
}

// MARK: - Status Bar
struct StatusBar: View {
    @ObservedObject var mapState: MapState
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        HStack(spacing: 12) {
            // GPS Status
            StatusIndicator(
                icon: "location.circle.fill",
                text: "GPS",
                isActive: locationManager.authorizationStatus == .authorizedWhenInUse
            )
            
            // ADS-B Status
            StatusIndicator(
                icon: "antenna.radiowaves.left.and.right",
                text: "ADS-B",
                isActive: true
            )
            
            // AHRS Status
            StatusIndicator(
                icon: "gyroscope",
                text: "AHRS",
                isActive: locationManager.heading != nil
            )
            
            // CO Monitor
            StatusIndicator(
                icon: "aqi.medium",
                text: "CO",
                isActive: true
            )
            
            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.3))
            
            // Wind Info
            Label("240° @ 28kt", systemImage: "wind")
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            // Flight Mode
            HStack(spacing: 4) {
                Image(systemName: mapState.mode.icon)
                    .foregroundColor(mapState.mode.color)
                Text(mapState.mode.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(mapState.mode.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(mapState.mode.color.opacity(0.2))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        .padding(.horizontal, 16)
    }
}

struct StatusIndicator: View {
    let icon: String
    let text: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(isActive ? .green : .red)
            Text(text)
                .font(.caption2)
                .foregroundColor(isActive ? .green : .red)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.3))
        .clipShape(Capsule())
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let onSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
            
            TextField("Search airports, routes...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .onSubmit(onSearch)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Button(action: onSearch) {
                Image(systemName: "paperplane")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Layer Controls
struct LayerControls: View {
    @ObservedObject var mapState: MapState
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LayerKind.allCases) { layer in
                    LayerButton(
                        layer: layer,
                        isActive: mapState.activeLayers.contains(layer),
                        action: { mapState.toggle(layer) }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct LayerButton: View {
    let layer: LayerKind
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: layer.systemImage)
                    .foregroundColor(isActive ? layer.color : .white.opacity(0.7))
                Text(layer.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? layer.color : .white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isActive ? layer.color.opacity(0.2) : Color.black.opacity(0.3)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isActive ? layer.color : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Floating Action Buttons
struct FloatingActionButtons: View {
    @ObservedObject var mapState: MapState
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Locate Button
            FloatingButton(
                icon: "location.fill",
                action: {
                    if let location = locationManager.lastLocation {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            mapState.camera = MKMapCamera(
                                lookingAtCenter: location.coordinate,
                                fromDistance: 25000,
                                pitch: 0,
                                heading: 0
                            )
                        }
                    }
                }
            )
            
            // Track Up/North Up Toggle
            FloatingButton(
                icon: "arrow.triangle.2.circlepath.camera",
                action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        mapState.camera.heading = (mapState.camera.heading + 90)
                            .truncatingRemainder(dividingBy: 360)
                    }
                }
            )
            
            // Record Track
            FloatingButton(
                icon: "record.circle",
                action: {
                    // Start/stop track recording
                }
            )
            
            // Flight Mode Toggle
            FloatingButton(
                icon: mapState.mode == .fly ? "airplane.circle.fill" : "paperplane.circle",
                action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mapState.mode = mapState.mode == .fly ? .plan : .fly
                    }
                }
            )
        }
    }
}

struct FloatingButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Annotation Bar View
struct AnnotationBarView: View {
    @ObservedObject var mapState: MapState
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let airport = mapState.selectedAirport {
                // Main annotation bar
                Button(action: {
                    showingDetails.toggle()
                }) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        // Main info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(airport.icao)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("\(airport.name), \(airport.city)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Quick stats
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("15nm")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Text("\(airport.elevation)'")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        
                        // Expand arrow
                        Image(systemName: showingDetails ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                // Detailed view
                if showingDetails {
                    AirportAnalysisView(airport: airport)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

// MARK: - Airport Analysis View
struct AirportAnalysisView: View {
    let airport: Airport
    
    var body: some View {
        VStack(spacing: 16) {
            // Airport info
            AnalysisSection(title: "Airport Information") {
                AnalysisRow(label: "ICAO", value: airport.icao)
                AnalysisRow(label: "Name", value: airport.name)
                AnalysisRow(label: "Location", value: "\(airport.city), \(airport.state)")
                AnalysisRow(label: "Elevation", value: "\(airport.elevation)'")
            }
            
            // Navigation
            AnalysisSection(title: "Navigation") {
                AnalysisRow(label: "Distance", value: "15 nm")
                AnalysisRow(label: "Bearing", value: "245°")
            }
            
            // Runways
            AnalysisSection(title: "Runways") {
                ForEach(airport.runways) { runway in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(runway.designation)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(runway.length)' × \(runway.width)' - \(runway.surface)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // Frequencies
            AnalysisSection(title: "Frequencies") {
                ForEach(airport.frequencies) { frequency in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(frequency.type): \(frequency.frequency)")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(frequency.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // Services
            AnalysisSection(title: "Services") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(airport.services, id: \.self) { service in
                        Text(service)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Analysis Section
struct AnalysisSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            content
                .padding(12)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Analysis Row
struct AnalysisRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}


