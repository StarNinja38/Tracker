import UIKit

// MARK: - UIColorMarshalling

/// `UIColor` нельзя положить в Core Data как есть, поэтому цвет хранится
/// hex-строкой вида `#FD4C49`.
enum UIColorMarshalling {

    static func hexString(from color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        return String(
            format: "#%02X%02X%02X",
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }

    static func color(from hex: String) -> UIColor {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: digits).scanHexInt64(&rgb)
        return UIColor(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
            blue: CGFloat(rgb & 0x0000FF) / 255,
            alpha: 1
        )
    }
}
