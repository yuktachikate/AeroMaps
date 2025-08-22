import SwiftUI

struct FlightPlannerView: View {
    @ObservedObject var mapState: MapState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAircraft = "C172"
    @State private var pilotName = ""
    @State private var passengerCount = 0
    @State private var fuelOnBoard = 40.0
    @State private var showingAircraftSelector = false
    
    let aircraft = [
        ("C172", "Cessna 172 Skyhawk", 120.0, 8.5),
        ("PA28", "Piper PA-28 Cherokee", 130.0, 9.0),
        ("SR22", "Cirrus SR22", 180.0, 12.0),
        ("DA40", "Diamond DA40", 140.0, 9.5)
    ]
    
    var selectedAircraftData: (String, String, Double, Double) {
        aircraft.first { $0.0 == selectedAircraft } ?? aircraft[0]
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Aircraft Selection
                    AircraftSection(
                        selectedAircraft: selectedAircraft,
                        aircraftData: selectedAircraftData,
                        onSelect: { showingAircraftSelector = true }
                    )
                    
                    // Flight Details
                    FlightDetailsSection(
                        pilotName: $pilotName,
                        passengerCount: $passengerCount,
                        fuelOnBoard: $fuelOnBoard
                    )
                    
                    // Route Summary
                    RouteSummarySection(mapState: mapState)
                    
                    // Weight & Balance
                    WeightBalanceSection(
                        aircraftData: selectedAircraftData,
                        passengerCount: passengerCount,
                        fuelOnBoard: fuelOnBoard
                    )
                    
                    // Performance
                    PerformanceSection(
                        route: mapState.route,
                        aircraftData: selectedAircraftData
                    )
                    
                    // Action Buttons
                    ActionButtonsSection(mapState: mapState)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Flight Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save flight plan
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showingAircraftSelector) {
            AircraftSelectorView(
                selectedAircraft: $selectedAircraft,
                aircraft: aircraft
            )
        }
    }
}

// MARK: - Aircraft Section
struct AircraftSection: View {
    let selectedAircraft: String
    let aircraftData: (String, String, Double, Double)
    let onSelect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Aircraft", icon: "airplane", color: .blue)
            
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(aircraftData.1)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 16) {
                            Label("\(Int(aircraftData.2)) kt", systemImage: "speedometer")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Label("\(aircraftData.3) gph", systemImage: "fuelpump")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Flight Details Section
struct FlightDetailsSection: View {
    @Binding var pilotName: String
    @Binding var passengerCount: Int
    @Binding var fuelOnBoard: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Flight Details", icon: "person.2.fill", color: .green)
            
            VStack(spacing: 16) {
                // Pilot Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pilot Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    TextField("Enter pilot name", text: $pilotName)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Passenger Count
                VStack(alignment: .leading, spacing: 8) {
                    Text("Passengers")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Button(action: { passengerCount = max(0, passengerCount - 1) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        
                        Text("\(passengerCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(minWidth: 60)
                        
                        Button(action: { passengerCount = min(3, passengerCount + 1) }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Text("Max: 3")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Fuel On Board
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fuel On Board")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("\(String(format: "%.1f", fuelOnBoard)) gal")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Max: 56 gal")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Slider(value: $fuelOnBoard, in: 0...56, step: 0.5)
                        .accentColor(.blue)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Route Summary Section
struct RouteSummarySection: View {
    @ObservedObject var mapState: MapState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Route", icon: "map.fill", color: .orange)
            
            if mapState.route.waypoints.count >= 2 {
                VStack(spacing: 12) {
                    ForEach(Array(mapState.route.waypoints.enumerated()), id: \.element.id) { index, waypoint in
                        RouteWaypointRow(
                            waypoint: waypoint,
                            isFirst: index == 0,
                            isLast: index == mapState.route.waypoints.count - 1
                        )
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Distance")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(Int(mapState.route.totalDistance)) NM")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Estimated Time")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(formatTime(mapState.route.estimatedTime))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            } else {
                Text("No route planned")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

struct RouteWaypointRow: View {
    let waypoint: Airport
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack {
            if isFirst {
                Image(systemName: "airplane.departure")
                    .foregroundColor(.green)
            } else if isLast {
                Image(systemName: "airplane.arrival")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(waypoint.icao)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(waypoint.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("\(waypoint.elevation) ft")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Weight & Balance Section
struct WeightBalanceSection: View {
    let aircraftData: (String, String, Double, Double)
    let passengerCount: Int
    let fuelOnBoard: Double
    
    // Simplified W&B calculations
    var emptyWeight: Double { 1600 } // lbs
    var emptyMoment: Double { 60000 } // lb-in
    var pilotWeight: Double { 180 } // lbs
    var passengerWeight: Double { 170 } // lbs per passenger
    var fuelWeight: Double { fuelOnBoard * 6.0 } // 6 lbs/gal
    
    var totalWeight: Double {
        emptyWeight + pilotWeight + (Double(passengerCount) * passengerWeight) + fuelWeight
    }
    
    var totalMoment: Double {
        emptyMoment + (pilotWeight * 37) + (Double(passengerCount) * passengerWeight * 55) + (fuelWeight * 48)
    }
    
    var cg: Double {
        totalMoment / totalWeight
    }
    
    var isInLimits: Bool {
        cg >= 35 && cg <= 47 // Simplified CG limits
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Weight & Balance", icon: "scalemass", color: .yellow)
            
            VStack(spacing: 12) {
                // Weight Breakdown
                VStack(spacing: 8) {
                    WeightRow(label: "Empty Weight", weight: emptyWeight, color: .gray)
                    WeightRow(label: "Pilot", weight: pilotWeight, color: .blue)
                    WeightRow(label: "Passengers", weight: Double(passengerCount) * passengerWeight, color: .green)
                    WeightRow(label: "Fuel", weight: fuelWeight, color: .orange)
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    WeightRow(label: "Total", weight: totalWeight, color: .white, isTotal: true)
                }
                
                // CG Indicator
                VStack(spacing: 8) {
                    Text("Center of Gravity")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("35\"")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 8)
                                .clipShape(Capsule())
                            
                            Rectangle()
                                .fill(isInLimits ? Color.green : Color.red)
                                .frame(width: 60, height: 8)
                                .clipShape(Capsule())
                                .offset(x: CGFloat((cg - 35) / 12) * 60)
                        }
                        
                        Text("47\"")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text("CG: \(String(format: "%.1f", cg))\"")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isInLimits ? .green : .red)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct WeightRow: View {
    let label: String
    let weight: Double
    let color: Color
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .subheadline : .caption)
                .fontWeight(isTotal ? .bold : .medium)
                .foregroundColor(color)
            
            Spacer()
            
            Text("\(Int(weight)) lbs")
                .font(isTotal ? .subheadline : .caption)
                .fontWeight(isTotal ? .bold : .medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Performance Section
struct PerformanceSection: View {
    let route: RoutePlan
    let aircraftData: (String, String, Double, Double)
    
    var fuelRequired: Double {
        (route.estimatedTime / 3600) * aircraftData.3
    }
    
    var fuelReserve: Double {
        fuelRequired * 0.3 // 30% reserve
    }
    
    var totalFuelNeeded: Double {
        fuelRequired + fuelReserve
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Performance", icon: "chart.line.uptrend.xyaxis", color: .purple)
            
            VStack(spacing: 12) {
                PerformanceRow(label: "Cruise Speed", value: "\(Int(aircraftData.2)) kt", color: .blue)
                PerformanceRow(label: "Fuel Burn", value: "\(aircraftData.3) gph", color: .orange)
                PerformanceRow(label: "Fuel Required", value: "\(String(format: "%.1f", fuelRequired)) gal", color: .green)
                PerformanceRow(label: "Fuel Reserve", value: "\(String(format: "%.1f", fuelReserve)) gal", color: .yellow)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                PerformanceRow(label: "Total Fuel Needed", value: "\(String(format: "%.1f", totalFuelNeeded)) gal", color: .white, isTotal: true)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PerformanceRow: View {
    let label: String
    let value: String
    let color: Color
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .subheadline : .caption)
                .fontWeight(isTotal ? .bold : .medium)
                .foregroundColor(color)
            
            Spacer()
            
            Text(value)
                .font(isTotal ? .subheadline : .caption)
                .fontWeight(isTotal ? .bold : .medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Action Buttons Section
struct ActionButtonsSection: View {
    @ObservedObject var mapState: MapState
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Generate flight plan
            }) {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("Generate Flight Plan")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Button(action: {
                // File flight plan
            }) {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("File Flight Plan")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Aircraft Selector
struct AircraftSelectorView: View {
    @Binding var selectedAircraft: String
    let aircraft: [(String, String, Double, Double)]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(aircraft, id: \.0) { aircraft in
                    Button(action: {
                        selectedAircraft = aircraft.0
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(aircraft.1)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 16) {
                                    Label("\(Int(aircraft.2)) kt", systemImage: "speedometer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Label("\(aircraft.3) gph", systemImage: "fuelpump")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedAircraft == aircraft.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Aircraft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}
