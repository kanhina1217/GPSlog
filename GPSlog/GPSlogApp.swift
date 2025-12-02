import SwiftUI
import SwiftData

@main
struct GPSlogApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var motionService = MotionService()
    @StateObject private var locationService: LocationService
    
    init() {
        let store = DataStore()
        let motion = MotionService()
        _dataStore = StateObject(wrappedValue: store)
        _motionService = StateObject(wrappedValue: motion)
        _locationService = StateObject(wrappedValue: LocationService(dataStore: store, motionService: motion))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(motionService)
                .environmentObject(locationService)
                .modelContainer(dataStore.container)
        }
    }
}
