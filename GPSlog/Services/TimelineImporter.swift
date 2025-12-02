import Foundation
import CoreLocation

class TimelineImporter {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    struct GoogleTimelineJSON: Codable {
        let locations: [GoogleLocation]?
    }
    
    struct GoogleLocation: Codable {
        let timestampMs: String?
        let latitudeE7: Int?
        let longitudeE7: Int?
        let accuracy: Int?
        let velocity: Int?
        let heading: Int?
        let altitude: Int?
        let activity: [GoogleActivityWrapper]?
    }
    
    struct GoogleActivityWrapper: Codable {
        let activity: [GoogleActivity]?
    }
    
    struct GoogleActivity: Codable {
        let type: String?
        let confidence: Int?
    }
    
    func importJSON(url: URL) async throws -> Int {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let timeline = try decoder.decode(GoogleTimelineJSON.self, from: data)
        
        guard let locations = timeline.locations else { return 0 }
        
        var count = 0
        for loc in locations {
            guard let latE7 = loc.latitudeE7,
                  let lonE7 = loc.longitudeE7,
                  let timeStr = loc.timestampMs,
                  let timeMs = Double(timeStr) else { continue }
            
            let lat = Double(latE7) / 1e7
            let lon = Double(lonE7) / 1e7
            let date = Date(timeIntervalSince1970: timeMs / 1000.0)
            
            // Extract best activity
            var activityType: String?
            if let activities = loc.activity?.first?.activity {
                activityType = activities.max(by: { ($0.confidence ?? 0) < ($1.confidence ?? 0) })?.type
            }
            
            let log = LocationLog(
                timestamp: date,
                latitude: lat,
                longitude: lon,
                altitude: Double(loc.altitude ?? 0),
                horizontalAccuracy: Double(loc.accuracy ?? 0),
                speed: Double(loc.velocity ?? 0),
                course: Double(loc.heading ?? 0),
                activityType: activityType
            )
            
            await MainActor.run {
                dataStore.saveLocation(log)
            }
            count += 1
        }
        return count
    }
}
