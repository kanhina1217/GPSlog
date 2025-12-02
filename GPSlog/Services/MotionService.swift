import Foundation
import CoreMotion
import Combine

class MotionService: ObservableObject {
    private let activityManager = CMMotionActivityManager()
    @Published var currentActivity: String = "Unknown"
    @Published var isMoving: Bool = false
    
    func startMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else {
            print("Motion Activity not available")
            return
        }
        
        activityManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self = self, let activity = activity else { return }
            self.updateActivity(activity)
        }
    }
    
    private func updateActivity(_ activity: CMMotionActivity) {
        var types: [String] = []
        if activity.walking { types.append("Walking") }
        if activity.running { types.append("Running") }
        if activity.automotive { types.append("Automotive") }
        if activity.cycling { types.append("Cycling") }
        if activity.stationary { types.append("Stationary") }
        
        if types.isEmpty {
            self.currentActivity = "Unknown"
        } else {
            self.currentActivity = types.joined(separator: ", ")
        }
        
        // Simple logic: if stationary, not moving. Else (walking, running, automotive, cycling), moving.
        // Note: Unknown might be moving or not.
        self.isMoving = !activity.stationary
    }
    
    func stopMonitoring() {
        activityManager.stopActivityUpdates()
    }
}
