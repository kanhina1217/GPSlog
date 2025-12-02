import Foundation
import CoreLocation

class TimelineImporter {
    private let dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    // Semantic Location History Format
    struct SemanticSegment: Codable {
        let startTime: String?
        let endTime: String?
        let activity: SemanticActivity?
        let visit: SemanticVisit?
    }
    
    struct SemanticActivity: Codable {
        let start: String? // "geo:lat,lon"
        let end: String?
        let topCandidate: SemanticCandidate?
    }
    
    struct SemanticVisit: Codable {
        let topCandidate: SemanticPlaceCandidate?
    }
    
    struct SemanticCandidate: Codable {
        let type: String?
    }
    
    struct SemanticPlaceCandidate: Codable {
        let placeLocation: String? // "geo:lat,lon"
        let placeID: String?
    }

    func importJSON(url: URL) async throws -> Int {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        // Try parsing as Semantic Location History (Array)
        if let segments = try? decoder.decode([SemanticSegment].self, from: data) {
            return await importSemanticSegments(segments)
        }
        
        // Fallback to old Raw Location History (Object)
        // (Keeping old logic if needed, or just replacing it. Let's keep it simple and focus on the new one for now as per user file)
        return 0
    }
    
    private func importSemanticSegments(_ segments: [SemanticSegment]) async -> Int {
        var count = 0
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] 
        // Note: The JSON has "2025-11-20T12:28:30.434+09:00". ISO8601DateFormatter should handle this.
        
        for segment in segments {
            guard let startTimeStr = segment.startTime,
                  let date = dateFormatter.date(from: startTimeStr) else { continue }
            
            if let activity = segment.activity {
                // Activity Segment
                // Parse start location "geo:lat,lon"
                if let startGeo = activity.start, let coord = parseGeo(startGeo) {
                    let log = LocationLog(
                        timestamp: date,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        altitude: 0,
                        horizontalAccuracy: 0,
                        speed: 0,
                        course: 0,
                        activityType: activity.topCandidate?.type
                    )
                    await MainActor.run { dataStore.saveLocation(log) }
                    count += 1
                }
            } else if let visit = segment.visit {
                // Visit Segment
                if let placeGeo = visit.topCandidate?.placeLocation, let coord = parseGeo(placeGeo) {
                    let log = VisitLog(
                        arrivalDate: date,
                        departureDate: dateFormatter.date(from: segment.endTime ?? "") ?? date,
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        horizontalAccuracy: 0,
                        placeName: visit.topCandidate?.placeID // Using ID as name for now
                    )
                    await MainActor.run { dataStore.saveVisit(log) }
                    count += 1
                }
            }
        }
        return count
    }
    
    private func parseGeo(_ geo: String) -> (latitude: Double, longitude: Double)? {
        // Format: "geo:35.498861,139.678590"
        let components = geo.replacingOccurrences(of: "geo:", with: "").split(separator: ",")
        guard components.count == 2,
              let lat = Double(components[0]),
              let lon = Double(components[1]) else { return nil }
        return (lat, lon)
    }
}
