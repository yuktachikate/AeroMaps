# AeroMaps - Professional Aviation App

A beautiful, modern aviation app built with SwiftUI that provides a Google Maps-style interface for flight planning and navigation. This app demonstrates advanced iOS development techniques with a focus on aviation-specific features.

## Features

### 🗺️ Map-First Interface
- **Google Maps-style UI** with universal search
- **Interactive map** with aviation overlays
- **Draggable bottom sheet** for route information
- **Floating action buttons** for quick access to common functions

### ✈️ Flight Planning
- **Route planning** with waypoint management
- **Real-time distance and time calculations**
- **Aircraft selection** with performance data
- **Weight & Balance** calculations with visual indicators
- **Fuel planning** with reserve calculations

### 🌤️ Weather Integration
- **METAR/TAF** weather data
- **Radar and satellite** imagery
- **Winds aloft** information
- **Icing and turbulence** forecasts
- **Multi-tab weather panel**

### 🏢 Airport Information
- **Detailed airport data** including runways and frequencies
- **Weather information** for each airport
- **Services and facilities** listings
- **Interactive airport selection**

### 🎛️ Advanced Controls
- **Layer management** (airspace, terrain, weather, etc.)
- **Flight mode switching** (Plan/Fly/Review)
- **GPS and ADS-B** status indicators
- **Location services** integration

## Technical Highlights

### Architecture
- **SwiftUI** for modern UI development
- **MVVM pattern** with ObservableObject
- **MapKit integration** for mapping functionality
- **Core Location** for GPS services
- **Modular design** with reusable components

### UI/UX Design
- **Dark theme** optimized for aviation use
- **Glass morphism** effects with `.ultraThinMaterial`
- **Smooth animations** and transitions
- **Accessibility** considerations
- **Responsive design** for iPhone and iPad

### Data Management
- **Real-time weather** data simulation
- **Airport database** with comprehensive information
- **Route calculations** using Haversine formula
- **Performance calculations** for different aircraft

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- macOS 14.0 or later (for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd AeroMaps
   ```

2. **Open in Xcode**
   ```bash
   open AeroMaps.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd+R` to build and run

### Configuration

The app includes several configuration options:

- **Location Services**: The app requests location permission to show your position on the map
- **Airport Database**: Currently includes major California airports (KSFO, KSJC, KRNO, KSQL, KOAK)
- **Weather Data**: Simulated weather data for demonstration purposes

## Usage Guide

### Basic Navigation
1. **Search for airports** using the search bar (e.g., "KSFO", "KSJC")
2. **Tap the map** to add waypoints
3. **Use the bottom sheet** to view route information
4. **Toggle layers** using the layer controls

### Flight Planning
1. **Create a route** by searching or tapping waypoints
2. **Adjust altitude and speed** using the controls in the bottom sheet
3. **View performance data** including fuel requirements
4. **Check weight & balance** for your aircraft

### Weather Information
1. **Access weather panel** through the weather layer
2. **View METAR data** for airports
3. **Check forecasts** and winds aloft
4. **Monitor radar** and satellite imagery

## FFM: Risk-Aware Planning (Field Foundation Model)

Enhances planning with risk-aware route predictions, risk heatmaps, and real-time advisory messages.

### What it adds
- **FFM Plan button** in the bottom sheet triggers risk-aware planning
- **Risk overlays** via `MKTileOverlay` heatmaps (toggle the "FFM Risk" layer)
- **Advisory text** summarizing hazards and recommendations
- **Per-leg risks** (icing, turbulence, terrain)
- **Computed route polyline** when returned by the backend

### Configuration
- `AeroMaps/Info.plist` keys:
  - `FFMBaseURL` (string): base URL of the FFM backend, e.g. `https://api.yourdomain.com`
  - `FFMUseMock` (bool): set `true` to use bundled mock response

### How to use in the app
1. Add at least two waypoints (search or tap the map)
2. Tap "FFM Plan" in the bottom sheet
3. Toggle the "FFM Risk" layer in Layer Controls to show the heatmap
4. Read advisory and per-leg risks in the bottom sheet

### Mock mode (no server required)
- Set `FFMUseMock` to `true` in `Info.plist` and rebuild, or
- Change `computeFFMPlan()` to call `client.plan(request:useMock: true)` during development
- The bundled `AeroMaps/ffm_mock_response.json` powers the mock visuals

### Backend API (expected contract)
- Endpoint: `POST {FFMBaseURL}/v1/plan`
- Request body example:
  ```json
  {
    "aircraft": {"type": "GA", "trueAirspeedKTAS": 140, "fuelBurnGPH": 9.5},
    "route": [{"lat": 37.6213, "lon": -122.3790}, {"lat": 37.3639, "lon": -121.9289}],
    "policy": {"reserveMinutes": 45, "enforceMEF": true}
  }
  ```
- Response body example:
  ```json
  {
    "polyline": [{"lat": 37.6213, "lon": -122.3790}, {"lat": 37.3639, "lon": -121.9289}],
    "legRisks": [{"fromIndex": 0, "toIndex": 1, "icing": 0.2, "turbulence": 0.4, "terrain": 0.1}],
    "alternates": ["KOAK", "KSQL"],
    "advisory": "Moderate turbulence forecast along the route.",
    "riskTileTemplates": ["https://tiles.example.com/heat/{z}/{x}/{y}.png?token=..."]
  }
  ```

### Safety envelope applied client-side
- Reserve time enforced ≥ 45 minutes
- Altitudes clamped to a basic MEF-like floor
- TAS and fuel burn clamped to reasonable aircraft performance ranges

### Create a short FFM demo GIF (optional)
1. Record a brief simulator clip (10–15s):
   ```bash
   xcrun simctl io booted recordVideo --codec h264 /tmp/ffm_demo.mov &
   REC_PID=$!
   # Manually in the simulator: add 2 waypoints → tap "FFM Plan" → toggle "FFM Risk"
   sleep 15 && kill $REC_PID
   ```
2. Convert to GIF (requires ffmpeg):
   ```bash
   ffmpeg -y -i /tmp/ffm_demo.mov -vf "fps=15,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" media/ffm_demo.gif
   ```
3. Embed in README:
   ```markdown
   ![FFM Demo](media/ffm_demo.gif)
   ```

## Project Structure

```
AeroMaps/
├── AeroMapsApp.swift          # Main app entry point
├── ContentView.swift          # Main view with map and controls
├── BottomSheet.swift          # Draggable route information panel
├── AirportDetailView.swift    # Detailed airport information
├── FlightPlannerView.swift    # Comprehensive flight planning
├── WeatherPanelView.swift     # Weather information and forecasts
├── FFMClient.swift            # FFM client, models, and mock support
├── Assets.xcassets/           # App icons and assets
├── Info.plist                 # App configuration
├── ffm_mock_response.json     # Bundled mock response for FFM
└── Preview Content/           # SwiftUI preview assets
```

## Key Components

### MapState
Central state management for the app, handling:
- Map camera position and style
- Route planning and waypoints
- Layer visibility
- Flight mode

### LocationManager
Handles GPS and location services:
- Location authorization
- GPS updates
- Heading information

### WeatherService
Manages weather data:
- METAR/TAF information
- Weather data caching
- Airport weather lookup

## Customization

### Adding Airports
To add more airports, modify the `airports` dictionary in `MapState`:

```swift
let airports: [String: Airport] = [
    "KXXX": Airport(
        icao: "KXXX",
        name: "Your Airport",
        city: "Your City",
        state: "ST",
        coordinate: .init(latitude: 0.0, longitude: 0.0),
        elevation: 0,
        runways: [...],
        frequencies: [...],
        services: [...]
    )
]
```

### Adding Aircraft
To add more aircraft types, modify the `aircraft` array in `FlightPlannerView`:

```swift
let aircraft = [
    ("KXXX", "Your Aircraft", 120, 8.5),
    // Add more aircraft here
]
```

### Customizing UI
The app uses a consistent design system with:
- **Colors**: Defined in `LayerKind` and `FlightMode` enums
- **Typography**: System fonts with semantic sizing
- **Spacing**: Consistent padding and margins
- **Effects**: Glass morphism and shadows

## Future Enhancements

### Planned Features
- **Real weather API** integration
- **Flight plan filing** capabilities
- **Synthetic vision** display
- **Traffic awareness** systems
- **Offline map** support
- **Cloud sync** for flight plans

### Technical Improvements
- **Core Data** for persistent storage
- **Network layer** for API calls
- **Unit tests** for calculations
- **Performance optimization** for large datasets
- **Accessibility** improvements

## Contributing

This is a demonstration project showcasing advanced iOS development techniques. Feel free to:

1. **Fork the repository**
2. **Create feature branches**
3. **Submit pull requests**
4. **Report issues**

## License

This project is for educational and demonstration purposes. Please respect aviation regulations and safety requirements when using aviation software.

## Acknowledgments

- **ForeFlight** for inspiration in aviation app design
- **Apple** for SwiftUI and MapKit frameworks
- **Aviation community** for domain expertise

---

**Note**: This app is a demonstration and should not be used for actual flight planning without proper aviation data sources and regulatory compliance.
