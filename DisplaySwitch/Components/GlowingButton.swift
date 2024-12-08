import SwiftUI

extension Color {
  static let background = Color(NSColor.windowBackgroundColor)
}

struct GlowingButton: View {
  var iconName: String
  var action: () -> Void

  var body: some View {
    Button {
      action()
    } label: {
      Image(systemName: iconName)
        .symbolRenderingMode(.palette)
        .foregroundStyle(Color.primary, Color.background.opacity(0.5))
        .background(Color.background.opacity(0.6))
        .clipShape(Circle())
        .font(.system(size: 20, weight: .regular))
        .contentShape(Circle())
    }
    .buttonStyle(PlainButtonStyle())
    .shadow(color: Color.primary.opacity(0.5), radius: 2)
  }
}
