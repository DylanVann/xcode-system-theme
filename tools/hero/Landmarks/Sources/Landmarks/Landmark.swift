import Foundation
import Observation
import SwiftUI

/// A place worth visiting, with the metadata shown in ``LandmarkRow``.
/// See https://developer.apple.com/documentation/observation for details.
@Observable
final class Landmark: Identifiable {
    let id = UUID()
    var name: String
    var place: Place
    var rating = 0
    var isFavorite = false
    var coordinate = Coordinate(latitude: 37.8199, longitude: -122.4783)

    init(name: String, place: Place) {
        self.name = name
        self.place = place
    }

    // MARK: - Nested types

    enum Place: String, CaseIterable {
        case bridge, park, museum, coast
    }

    struct Coordinate: Hashable {
        var latitude: Double
        var longitude: Double
    }

    /// Distance to another landmark in kilometers, using the haversine formula.
    func distance(to other: Landmark) -> Double {
        let radius = 6371.0
        let dLat = (other.coordinate.latitude - coordinate.latitude) * .pi / 180
        let dLon = (other.coordinate.longitude - coordinate.longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(coordinate.latitude * .pi / 180) * cos(other.coordinate.latitude * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        return radius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

struct LandmarkRow: View {
    @State private var landmark = Landmark(name: "Golden Gate Bridge", place: .bridge)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: landmark.isFavorite ? "star.fill" : "star")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading) {
                Text(landmark.name).font(.headline)
                Text("\(landmark.place.rawValue.capitalized) · \(landmark.rating)/5")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .onTapGesture { landmark.isFavorite.toggle() }
    }
}

#Preview {
    LandmarkRow()
}
