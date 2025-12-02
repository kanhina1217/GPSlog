import SwiftUI
import SwiftData

struct LogListView: View {
    @Query(sort: \LocationLog.timestamp, order: .reverse) private var logs: [LocationLog]
    
    var body: some View {
        List {
            ForEach(logs.prefix(100)) { log in // Limit to 100 for performance in list
                VStack(alignment: .leading) {
                    HStack {
                        Text(log.timestamp, style: .time)
                            .font(.headline)
                        Spacer()
                        if let activity = log.activityType {
                            Text(activity)
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    HStack {
                        Text("Lat: \(log.latitude, specifier: "%.5f")")
                        Text("Lon: \(log.longitude, specifier: "%.5f")")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    if log.speed > 0 {
                        Text("Speed: \(log.speed, specifier: "%.1f") m/s")
                            .font(.caption2)
                    }
                }
            }
        }
        .navigationTitle("Logs")
    }
}
