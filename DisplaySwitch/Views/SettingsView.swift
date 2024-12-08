import ServiceManagement
import SwiftData
import SwiftUI

extension Bundle {
  var releaseVersionNumber: String? {
    return infoDictionary?["CFBundleShortVersionString"] as? String
  }
}

struct SettingsView: View {
  @Environment(\.modelContext) var modelContext

  @ObservedObject var updater: Updater = .shared

  @Bindable var globalListener: GlobalKeyboardListener = .shared

  @State var isBindFocus: Bool = false

  @Query var activeDisplayBind_: [Keybind]
  var activeDisplayBind: Keybind { activeDisplayBind_.first! }

  init() {
    let activeDisplay = KeybindUsage.activeDisplay.rawValue
    _activeDisplayBind_ = Query(filter: #Predicate<Keybind> { $0.usage == activeDisplay })
  }

  var body: some View {
    ZStack {
      Color.clear
        .contentShape(Rectangle())
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
          DispatchQueue.main.async {
            NSApp.keyWindow?.makeFirstResponder(nil)
          }
        }

      VStack {
        VStack {
          HStack {
            Text("Launch at login: ")
            Image(systemName: "circle.fill")
              .foregroundStyle(LaunchAtStartup.shared.isEnabled ? Color.green : Color.red)
            if !LaunchAtStartup.shared.isEnabled {
              Button("Open system settings") {
                SMAppService.openSystemSettingsLoginItems()
              }
            }
          }
          Text(LaunchAtStartup.shared.isEnabled ? "DisplaySwitch will launch at login" : "Press the button to open system settings and allow the DisplaySwitch application to be launched at login")
            .font(.subheadline)
            .foregroundStyle(.gray)
        }
        Divider()
          .padding([.bottom, .top], 6.0)
        VStack {
          HStack {
            Text("Input permissions: ")
            Image(systemName: "circle.fill")
              .foregroundStyle(globalListener.accessibilityEnabled ? Color.green : Color.red)
            if !globalListener.accessibilityEnabled {
              Button("Open system settings") {}
            }
          }
          Text(globalListener.accessibilityEnabled ? "Keybindings are enabled system-wide" : "Press the button to open system settings and allow input monitoring for keybindings to work correctly")
            .font(.subheadline)
            .foregroundStyle(.gray)
        }
        .padding([.bottom], 6.0)
        VStack {
          VStack(alignment: .leading) {
            HStack {
              Text("Disable current display: ")
              KeybindInput(bind: activeDisplayBind)
            }
            Text("Disables the display that the cursor is currently on")
              .font(.subheadline)
              .foregroundStyle(.gray)
          }
        }
        Spacer()
        HStack {
          Text("Version: \(Bundle.main.releaseVersionNumber ?? "unknown")")
          Spacer()
          Button("Check for updates") {
            Updater.shared.updater.checkForUpdates()
          }
          .disabled(!Updater.shared.canCheckForUpdates)
        }
        Divider()
        HStack(spacing: 4.0) {
          Image(systemName: "exclamationmark.triangle.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(Color.black, Color.yellow)
          Text("NOTE:")
            .bold()
            .padding([.trailing], 2.0)
          Text("To connect all displays back you can quickly press the ⌘ button 5 times on your keyboard")
        }
        .padding([.top], 2.0)
      }
      .frame(maxWidth: .infinity)
      .padding()
    }
  }
}

#Preview {
  let previewContainer: ModelContainer = {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Keybind.self, configurations: config)

    container.mainContext.insert(Keybind(KeybindUsage.activeDisplay))

    return container
  }()

  SettingsView()
    .frame(maxWidth: 640, maxHeight: 640)
    .modelContainer(previewContainer)
}
