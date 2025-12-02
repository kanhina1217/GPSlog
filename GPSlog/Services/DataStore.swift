import Foundation
import SwiftData
import Combine

@MainActor
class DataStore: ObservableObject {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                LocationLog.self,
                VisitLog.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    func saveLocation(_ location: LocationLog) {
        let context = container.mainContext
        context.insert(location)
        // Auto-save is generally handled by SwiftData, but explicit save can be done if needed
    }
    
    func saveVisit(_ visit: VisitLog) {
        let context = container.mainContext
        context.insert(visit)
    }
    
    func fetchRecentLogs(limit: Int = 100) -> [LocationLog] {
        let context = container.mainContext
        let descriptor = FetchDescriptor<LocationLog>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        // Note: FetchDescriptor doesn't support 'limit' directly in all versions easily without more code, 
        // but we can fetch and prefix. For efficiency in a real app, we'd use more advanced predicates or paging.
        // For now, fetching all might be heavy, so let's try to be careful.
        // SwiftData's FetchDescriptor is powerful.
        
        do {
            var logs = try context.fetch(descriptor)
            if logs.count > limit {
                logs = Array(logs.prefix(limit))
            }
            return logs
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }
}
