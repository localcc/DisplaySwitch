import Foundation
import SwiftUI

struct ErrorWindowView: View {
  var errorText: String
  let onDismiss: () -> Void

  var body: some View {
    VStack(alignment: .center, spacing: 10.0) {
      HStack {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 36, weight: .bold))
          .symbolRenderingMode(.palette)
          .foregroundStyle(Color.black, Color.yellow)
        Text("An error has occurred").font(.title)
      }
      Text(errorText)
      Text("Restarting the application may help fix the issue.")

      HStack {
        Spacer()
        Button("Ok", action: onDismiss)
      }
    }
    .padding()
    .frame(maxWidth: 400)
  }
}

#Preview {
  ErrorWindowView(errorText: "Failed to register CoreGraphics display update callbacks. Displays that are reconnected may not be detected.") {}
}
