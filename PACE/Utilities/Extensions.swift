import Foundation
import SwiftUI
import CoreLocation

// MARK: - View Extensions

extension View {
    func paceBackground() -> some View {
        self.background(PACEColors.backgroundPrimary.ignoresSafeArea())
    }

    func cardStyle() -> some View {
        self
            .background(PACEColors.surface)
            .cornerRadius(16)
    }

    func metricLabel(_ text: String) -> some View {
        VStack(spacing: 2) {
            self
            Text(text)
                .font(PACEFonts.metricLabel)
                .foregroundStyle(PACEColors.textSecondary)
                .tracking(3)
        }
    }
}

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - TimeInterval

extension TimeInterval {
    var paceString: String { PACEFormatter.formatSecondsPerUnit(self) }
    var durationString: String { PACEFormatter.duration(self) }
}

// MARK: - CLLocationCoordinate2D

extension Array where Element == CLLocationCoordinate2D {
    var boundingRegion: MKCoordinateRegion? {
        guard !isEmpty else { return nil }
        var minLat = self[0].latitude, maxLat = self[0].latitude
        var minLon = self[0].longitude, maxLon = self[0].longitude
        for c in self {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - MapKit (only imported when needed)

import MapKit
