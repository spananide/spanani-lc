import Foundation

// The package used Bundle.module; merged into the LC framework, resources live in this framework's bundle.
private final class SpananiBundleToken {}

enum SpananiBundle {
    static let bundle = Bundle(for: SpananiBundleToken.self)
}
