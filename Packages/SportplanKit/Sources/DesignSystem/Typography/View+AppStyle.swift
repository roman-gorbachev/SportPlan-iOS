import SwiftUI

extension View {
    public func appStyle(_ style: TypeStyle) -> some View {
        return font(style.font)
    }
}
