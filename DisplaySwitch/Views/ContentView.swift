import Combine
import SwiftData
import SwiftUI

struct ForegroundAccentColor: ViewModifier {
  func body(content: Content) -> some View {
    content.foregroundStyle(Color.accentColor)
  }
}

struct ContentView: View {
  @Environment(\.modelContext) var modelContext
  @Environment(\.openWindow) var openWindow
  @Query(sort: \Display.name) var displays: [Display]

  @State
  private var error: String? = nil

  var scrollContents: some View {
    VStack(spacing: 2.0) {
      ScrollView {
        ForEach(displays) { display in
          DisplayRow(display: display)
            .onChange(of: displays) {}
        }
      }
      .scrollIndicators(.never)
    }
    .padding([.horizontal], 3.0)
    .frame(maxWidth: .infinity)
    .background(Color.clear)
  }

  var body: some View {
    VStack(spacing: 8.0) {
      scrollContents
      VStack {
        HStack {
          Spacer()
          GlowingButton(iconName: "arrow.uturn.backward.circle.fill") {
            Task {
              do {
                try await DisplayController.instance.connectAll()
              } catch let err {
                withAnimation(.easeIn(duration: 0.2)) {
                  $error.wrappedValue = err.localizedDescription
                }
              }
            }
          }
          .help("Connect all displays back")
          GlowingButton(iconName: "arrow.clockwise.circle.fill") {
            Task {
              await DisplayController.instance.refreshDisplays(clearDisconnected: NSEvent.modifierFlags.contains(.option))
            }
          }
          .help("Refresh displays. Hold option to remove all disconnected displays.")
          GlowingButton(iconName: "gear.circle.fill") {
            NSApplication.shared.activate()
            openWindow(id: "settings")
          }
          .help("Open application settings")
        }
        .padding([.horizontal], 11.25)
        if $error.wrappedValue != nil {
          Text("An error occurred: \($error.wrappedValue!)")
            .foregroundStyle(Color.red)
            .padding([.leading], 10.0)
        }
      }
    }
    .padding([.vertical], 6.0)
    .padding([.bottom], 2.0)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

#Preview {
  let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Display.self, configurations: config)

    container.mainContext.insert(Display(name: "DELL S27212DGFA", displayId: CGDirectDisplayID(), enabled: false))
    container.mainContext.insert(Display(name: "Apple Internal Display", displayId: CGDirectDisplayID(), enabled: true))

    return container
  }()

  ContentView()
    .frame(maxWidth: 240, maxHeight: 640)
    .modelContainer(previewContainer)
}
