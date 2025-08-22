import SwiftUI

struct BottomSheet: View {
    @ObservedObject var mapState: MapState
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded = false
    
    private let minHeight: CGFloat = 120
    private let maxHeight: CGFloat = 400
    
    var body: some View {
        GeometryReader { geometry in
            let height = max(minHeight, min(maxHeight, maxHeight - dragOffset))
            
            VStack(spacing: 0) {
                // Drag Handle
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                // Route Summary
                RouteSummaryView(mapState: mapState)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                
                // Waypoint Chips
                if !mapState.route.waypoints.isEmpty {
                    WaypointChipsView(mapState: mapState)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.horizontal, 16)
                
                // Flight Parameters
                FlightParametersView(mapState: mapState)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                
                // Action Buttons
                ActionButtonsView(mapState: mapState)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                // FFM Advisory and Risks
                if !mapState.ffmAdvice.isEmpty || !mapState.legRisks.isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 16)
                    VStack(alignment: .leading, spacing: 8) {
                        if !mapState.ffmAdvice.isEmpty {
                            Text("Advisory")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text(mapState.ffmAdvice)
                                .font(.footnote)
                                .foregroundColor(.white)
                        }
                        if !mapState.legRisks.isEmpty {
                            Text("Per-Leg Risk")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            ForEach(Array(mapState.legRisks.enumerated()), id: \.offset) { _, leg in
                                HStack {
                                    Text("Leg \(leg.fromIndex + 1)→\(leg.toIndex + 1)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Label(String(format: "Icing %.1f", leg.icing), systemImage: "snow")
                                        .font(.caption2)
                                        .foregroundColor(.cyan)
                                    Label(String(format: "Turb %.1f", leg.turbulence), systemImage: "wind")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                    Label(String(format: "Terrain %.1f", leg.terrain), systemImage: "mountain.2")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                
                Spacer()
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
            .position(x: geometry.size.width / 2, y: geometry.size.height - height / 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = min(max(0, value.translation.height), maxHeight - minHeight)
                    }
                    .onEnded { value in
                        let threshold = (maxHeight - minHeight) / 2
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            dragOffset = value.translation.height > threshold ? (maxHeight - minHeight) : 0
                            isExpanded = value.translation.height > threshold
                        }
                    }
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Route Summary
struct RouteSummaryView: View {
    @ObservedObject var mapState: MapState
    
    var body: some View {
        HStack {
            if mapState.route.waypoints.count >= 2 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(mapState.route.waypoints.first!.icao) → \(mapState.route.waypoints.last!.icao)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(mapState.route.waypoints.first!.name) to \(mapState.route.waypoints.last!.name)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Label("\(Int(mapState.route.totalDistance)) NM", systemImage: "ruler")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Label(formatTime(mapState.route.estimatedTime), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Label("\(String(format: "%.1f", mapState.route.fuelRequired)) gal", systemImage: "fuelpump")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plan a Route")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Search for airports or tap the map to add waypoints")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: { mapState.showingFlightPlanner = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

// MARK: - Waypoint Chips
struct WaypointChipsView: View {
    @ObservedObject var mapState: MapState
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(mapState.route.waypoints.enumerated()), id: \.element.id) { index, waypoint in
                    WaypointChip(
                        waypoint: waypoint,
                        isFirst: index == 0,
                        isLast: index == mapState.route.waypoints.count - 1
                    )
                }
                
                if !mapState.route.waypoints.isEmpty {
                    Button(action: { mapState.clearRoute() }) {
                        Label("Clear", systemImage: "trash")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.red.opacity(0.4), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct WaypointChip: View {
    let waypoint: Airport
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            if isFirst {
                Image(systemName: "airplane.departure")
                    .foregroundColor(.green)
            } else if isLast {
                Image(systemName: "airplane.arrival")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .foregroundColor(.blue)
            }
            
            Text(waypoint.icao)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Flight Parameters
struct FlightParametersView: View {
    @ObservedObject var mapState: MapState
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Altitude")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Button(action: { mapState.route.altitudeFT = max(2000, mapState.route.altitudeFT - 1000) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(mapState.route.altitudeFT.formatted()) ft")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(minWidth: 80)
                    
                    Button(action: { mapState.route.altitudeFT = min(18000, mapState.route.altitudeFT + 1000) }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.2))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Cruise Speed")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Button(action: { mapState.route.cruiseKTAS = max(80, mapState.route.cruiseKTAS - 5) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(Int(mapState.route.cruiseKTAS)) kt")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(minWidth: 60)
                    
                    Button(action: { mapState.route.cruiseKTAS = min(220, mapState.route.cruiseKTAS + 5) }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Action Buttons
struct ActionButtonsView: View {
    @ObservedObject var mapState: MapState
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ActionButton(
                    title: "FFM Plan",
                    icon: "flame.fill",
                    color: .pink
                ) {
                    Task { await mapState.computeFFMPlan() }
                }
                ActionButton(
                    title: "Route Advisor",
                    icon: "point.topleft.down.curvedto.point.filled.to.point.bottomright.up",
                    color: .blue
                ) {
                    // Show route advisor with ATC-preferred routes
                    if mapState.route.waypoints.count >= 2 {
                        let origin = mapState.route.waypoints.first!.icao
                        let destination = mapState.route.waypoints.last!.icao
                        print("Route Advisor: \(origin) → \(destination)")
                        // In a real app, this would show ATC-preferred routes
                    }
                }
                
                ActionButton(
                    title: "Procedure Advisor",
                    icon: "arrow.triangle.merge",
                    color: .purple
                ) {
                    // Show available procedures for selected airport
                    if let airport = mapState.selectedAirport {
                        print("Procedure Advisor for \(airport.icao): SIDs, STARs, Approaches")
                        // In a real app, this would show available procedures
                    }
                }
                
                ActionButton(
                    title: "Profile / 3D",
                    icon: "square.grid.3x3",
                    color: .orange
                ) {
                    // Show 3D route profile with terrain
                    if mapState.route.waypoints.count >= 2 {
                        print("Profile/3D: Showing terrain and altitude profile")
                        // In a real app, this would show 3D route visualization
                    }
                }
                
                ActionButton(
                    title: "Plates",
                    icon: "doc.richtext",
                    color: .green
                ) {
                    // Show approach plates and airport diagrams
                    if let airport = mapState.selectedAirport {
                        print("Plates: Showing approach plates for \(airport.icao)")
                        // In a real app, this would show approach plates
                    }
                }
                
                ActionButton(
                    title: "W&B",
                    icon: "scalemass",
                    color: .yellow
                ) {
                    // Open Weight & Balance calculator
                    mapState.showingFlightPlanner = true
                }
                
                ActionButton(
                    title: "Checklist",
                    icon: "checklist",
                    color: .cyan
                ) {
                    // Show preflight checklist
                    print("Checklist: Preflight, Takeoff, Landing, Emergency")
                    // In a real app, this would show interactive checklists
                }
                
                ActionButton(
                    title: "Brief & File",
                    icon: "paperplane",
                    color: .red
                ) {
                    // Open weather briefing and flight plan filing
                    mapState.showingWeatherPanel = true
                }
                
                ActionButton(
                    title: "Notes",
                    icon: "pencil.and.list.clipboard",
                    color: .gray
                ) {
                    // Open scratchpad for flight notes
                    print("Notes: Opening scratchpad for flight notes")
                    // In a real app, this would open a notes interface
                }
                
                ActionButton(
                    title: "Clear Route",
                    icon: "trash",
                    color: .red
                ) {
                    mapState.clearRoute()
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70, height: 60)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
