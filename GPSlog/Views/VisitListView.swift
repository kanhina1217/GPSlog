import SwiftUI
import SwiftData

struct VisitListView: View {
    @Query(sort: \VisitLog.arrivalDate, order: .reverse) private var visits: [VisitLog]
    
    var body: some View {
        List {
            ForEach(visits) { visit in
                VStack(alignment: .leading) {
                    Text(visit.placeName ?? "Unknown Place")
                        .font(.headline)
                    
                    HStack {
                        Text("Arr: \(visit.arrivalDate, style: .time)")
                        Text("Dep: \(visit.departureDate == Date.distantFuture ? "Present" : visit.departureDate.formatted(date: .omitted, time: .shortened))")
                    }
                    .font(.caption)
                    
                    Text("Duration: \(formatDuration(visit.duration))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Visits")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}
