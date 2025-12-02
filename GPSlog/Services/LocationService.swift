import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let dataStore: DataStore
    private let motionService: MotionService
    
    @Published var currentLocation: CLLocation?
    @Published var isTracking: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let highAccuracyInterval: TimeInterval = 10.0 // Seconds between high accuracy updates when moving
    private var highAccuracyTimer: Timer?
    
    init(dataStore: DataStore, motionService: MotionService) {
        self.dataStore = dataStore
        self.motionService = motionService
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone // We control updates manually or via significant changes
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false // We handle this
        locationManager.showsBackgroundLocationIndicator = false // Try to minimize, but "Always" might still show it depending on mode
        
        setupMotionBindings()
    }
    
    func requestPermissions() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking() {
        isTracking = true
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startMonitoringVisits()
        motionService.startMonitoring()
        
        // Initial high accuracy burst
        enableHighAccuracy()
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopMonitoringVisits()
        locationManager.stopUpdatingLocation()
        motionService.stopMonitoring()
        highAccuracyTimer?.invalidate()
    }
    
    private func setupMotionBindings() {
        motionService.$isMoving
            .sink { [weak self] isMoving in
                self?.handleMotionChange(isMoving: isMoving)
            }
            .store(in: &cancellables)
    }
    
    private func handleMotionChange(isMoving: Bool) {
        if isMoving {
            print("Motion detected: Moving. Enabling high accuracy.")
            enableHighAccuracy()
        } else {
            print("Motion detected: Stationary. Disabling high accuracy.")
            disableHighAccuracy()
        }
    }
    
    private func enableHighAccuracy() {
        // Start standard updates
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        // In a real "smart" app, we might want to pulse this to save battery.
        // For "real-time like" without constant drain, maybe we keep it on while moving?
        // Or we use a timer to turn it off and on.
        // Requirement: "Stop GPS completely when stopped, only high accuracy when moving"
        // So when moving, we keep it on? Or pulse it?
        // "High accuracy GPS for a short time only when moving" -> Pulse or just ON while moving?
        // Let's keep it ON while moving for now to ensure "real-time like" feel, 
        // but if the user stops, we kill it immediately.
    }
    
    private func disableHighAccuracy() {
        locationManager.stopUpdatingLocation()
        // We rely on Significant Location Changes to wake us up if Motion fails or if we move far.
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentLocation = location
        
        // Save to DB
        let log = LocationLog(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            speed: location.speed,
            course: location.course,
            activityType: motionService.currentActivity
        )
        
        // Run on MainActor for SwiftData
        Task { @MainActor in
            dataStore.saveLocation(log)
        }
        
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        // Save visit
        let log = VisitLog(
            arrivalDate: visit.arrivalDate,
            departureDate: visit.departureDate,
            latitude: visit.coordinate.latitude,
            longitude: visit.coordinate.longitude,
            horizontalAccuracy: visit.horizontalAccuracy
        )
        
        Task { @MainActor in
            dataStore.saveVisit(log)
        }
        
        print("Visit detected: \(visit.coordinate)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}
