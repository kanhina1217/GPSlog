import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var dataStore: DataStore
    @State private var showImport = false
    
    var body: some View {
        TabView {
            NavigationView {
                MapOverview()
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
            
            NavigationView {
                LogListView()
            }
            .tabItem {
                Label("Logs", systemImage: "list.bullet")
            }
            
            NavigationView {
                VisitListView()
            }
            .tabItem {
                Label("Visits", systemImage: "house")
            }
            
            NavigationView {
                VStack {
                    Button("Start Tracking") {
                        locationService.requestPermissions()
                        locationService.startTracking()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(locationService.isTracking)
                    
                    Button("Stop Tracking") {
                        locationService.stopTracking()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!locationService.isTracking)
                    
                    Divider().padding()
                    
                    Button("Import Google Timeline") {
                        showImport = true
                    }
                }
                .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .fileImporter(isPresented: $showImport, allowedContentTypes: [.json, .text, .content]) { result in
            switch result {
            case .success(let url):
                Task {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    let importer = TimelineImporter(dataStore: dataStore)
                    do {
                        let count = try await importer.importJSON(url: url)
                        print("Imported \(count) logs")
                    } catch {
                        print("Import failed: \(error)")
                    }
                }
            case .failure(let error):
                print("Import error: \(error)")
            }
        }
    }
}
