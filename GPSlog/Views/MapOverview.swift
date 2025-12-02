import SwiftUI
import MapKit
import SwiftData

struct MapOverview: View {
    @EnvironmentObject var locationService: LocationService
    @Query(sort: \LocationLog.timestamp, order: .reverse) private var logs: [LocationLog]
    
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            
            // Draw path from logs
            // Note: In a real app with thousands of points, we need to simplify this or use MKOverlayRenderer.
            // For SwiftUI Map, MapPolyline is available in iOS 17+.
            if !logs.isEmpty {
                MapPolyline(coordinates: logs.prefix(500).map { $0.coordinate })
                    .stroke(.blue, lineWidth: 3)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onAppear {
            if let last = logs.first {
                position = .region(MKCoordinateRegion(
                    center: last.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }
}
