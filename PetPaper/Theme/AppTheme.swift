import SwiftUI

enum AppTheme {
    static let coral = Color(red: 1.0, green: 0.45, blue: 0.42)
    static let peach = Color(red: 1.0, green: 0.72, blue: 0.58)
    static let cream = Color(red: 1.0, green: 0.97, blue: 0.93)
    static let ink = Color(red: 0.18, green: 0.14, blue: 0.16)
    static let muted = Color(red: 0.45, green: 0.38, blue: 0.40)
    static let card = Color.white
    static let mint = Color(red: 0.55, green: 0.86, blue: 0.75)
    static let sky = Color(red: 0.55, green: 0.75, blue: 0.98)
    static let lilac = Color(red: 0.78, green: 0.68, blue: 0.98)

    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.94, blue: 0.90),
            Color(red: 0.96, green: 0.92, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
