import UIKit

enum DeepLinkService {
    static func openDoorDash() {
        open("doordash://")
    }

    static func openUberEats() {
        open("ubereats://")
    }

    private static func open(_ scheme: String) {
        guard let url = URL(string: scheme) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
