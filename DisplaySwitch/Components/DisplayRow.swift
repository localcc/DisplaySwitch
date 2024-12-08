import Combine
import SwiftData
import SwiftUI

struct PowerCircle: View {
  var enabled: Bool

  var body: some View {
    if enabled {
      Image(systemName: "power.circle.fill")
        .font(.system(size: 24, weight: .regular))
        .symbolRenderingMode(.palette)
        .foregroundStyle(Color.primary, Color.accentColor)
        .transition(.opacity)
    } else {
      Image(systemName: "power.circle.fill")
        .font(.system(size: 24, weight: .regular))
        .symbolRenderingMode(.hierarchical)
    }
  }
}

struct NoTapStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.contentShape(Rectangle()).onTapGesture(perform: configuration.trigger)
  }
}

struct ItemHover: ViewModifier {
  func body(content: Content) -> some View {
    content
      .background(.tertiary)
      .clipShape(RoundedRectangle(cornerSize: CGSize(width: 4, height: 4)))
  }
}

struct DisplayRow: View {
  @Environment(\.modelContext) var modelContext
  @Environment(\.openWindow) var openWindow

  @Bindable var display: Display

  @State var error: String? = nil

  @State var lastUpdate = UUID()

  var body: some View {
    VStack(alignment: .leading, spacing: 6.0) {
      Button {
        withAnimation(.easeIn(duration: 0.2)) {
          display.enabled.toggle()
          _ = try? modelContext.save()
          let dto = display.toDTO()
          Task {
            _ = try? await DisplayController.instance.update(display: dto)
          }
        }
      } label: {
        HStack(alignment: .center) {
          Image(systemName: "display")
            .symbolRenderingMode(display.enabled ? .hierarchical : .monochrome)
          Text(display.name)
            .lineLimit(1)
          Spacer()
          PowerCircle(enabled: display.enabled)
        }
        .contentShape(Rectangle())
        .padding([.leading], 10.0)
        .padding([.trailing], 6.0)
        .padding([.vertical], 2.0)
      }
      .buttonStyle(PlainButtonStyle())
      .conditional(on: $error.wrappedValue != nil, ItemHover())
      if $error.wrappedValue != nil {
        Text("An error occurred: \($error.wrappedValue!)")
          .foregroundStyle(Color.red)
          .padding([.leading], 10.0)
      }
    }
  }
}

#Preview {
  DisplayRow(display: Display(name: "DELL S2721DGFA", displayId: CGDirectDisplayID(), enabled: true))
    .frame(maxWidth: 240, maxHeight: 640)
}
