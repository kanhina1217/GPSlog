import Foundation
import SwiftData
import CoreLocation

@Model
final class LocationLog {
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var horizontalAccuracy: Double
    var speed: Double
    var course: Double
    var activityType: String? // "walking", "automotive", etc.
    
    init(timestamp: Date, latitude: Double, longitude: Double, altitude: Double, horizontalAccuracy: Double, speed: Double, course: Double, activityType: String? = nil) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.course = course
        self.activityType = activityType
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@Model
final class VisitLog {
    var arrivalDate: Date
    var departureDate: Date
    var latitude: Double
    var longitude: Double
    var horizontalAccuracy: Double
    var placeName: String?
    
    init(arrivalDate: Date, departureDate: Date, latitude: Double, longitude: Double, horizontalAccuracy: Double, placeName: String? = nil) {
        self.arrivalDate = arrivalDate
        self.departureDate = departureDate
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.placeName = placeName
    }
    
    var duration: TimeInterval {
        departureDate.timeIntervalSince(arrivalDate)
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
