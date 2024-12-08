import AppKit
import MenuBarExtraAccess
import Sparkle
import SwiftData
import SwiftUI

@Observable
class DisplaySwitchAppDelegate: NSObject, NSApplicationDelegate {
  var openMenuBar = false
  var isFirstStart = false

  var errorWindow: NSWindow?

  override init() {}

  func updateFirstStart(_ firstStart: Bool) {
    self.isFirstStart = firstStart
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    Task {
      do {
        try await DisplayController.instance.initializeCallbacks()

        if self.isFirstStart {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.openMenuBar = true
          }
        }

        if !GlobalKeyboardListener.shared.initializeTaps() {
          self.showError(NSLocalizedString("Failed to initialize event taps. Keybindings will not work.", comment: ""))
        }
      } catch let err {
        showError(err.localizedDescription)
      }
    }
  }

  @MainActor
  func showError(_ err: String) {
    let contentView = ErrorWindowView(errorText: err) {
      if self.errorWindow != nil {
        self.errorWindow!.close()
      }
    }

    let window = self.getOrCreateWindow()

    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(nil)
    window.center()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
    self.openMenuBar.toggle()
    return true
  }

  @MainActor
  func getOrCreateWindow() -> NSWindow {
    if self.errorWindow != nil {
      return self.errorWindow!
    }

    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300), styleMask: [.titled, .closable], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false

    self.errorWindow = window
    return self.errorWindow!
  }
}

@main
struct DisplaySwitchApp: App {
  @Environment(\.openWindow) var openWindow
  @Environment(\.dismissWindow) var dismissWindow
  @Environment(\.scenePhase) var scenePhase

  @NSApplicationDelegateAdaptor private var appDelegate: DisplaySwitchAppDelegate

  @State var openMenuBar = false

  private var updaterController: SPUStandardUpdaterController

  init() {
    self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    Updater.initializedInstance = Updater(updater: self.updaterController.updater)

    DisplayController.initializedInstance = DisplayController(modelContainer: self.sharedModelContainer)
    GlobalKeyboardListener.initializedInstance = GlobalKeyboardListener(modelContainer: self.sharedModelContainer)

    let firstStart = (try? self.sharedModelContainer.mainContext.fetch(FetchDescriptor<FirstStart>()))?.first == nil
    self.appDelegate.updateFirstStart(firstStart)

    let modelContext = self.sharedModelContainer.mainContext
    DispatchQueue.main.async {
      if firstStart {
        modelContext.insert(FirstStart())
      }
    }
  }

  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Display.self,
      FirstStart.self,
      Keybind.self
    ])
    let fileManager = FileManager.default
    let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let directoryURL = appSupportURL.appendingPathComponent("DisplaySwitch")

    let fileURL = directoryURL.appendingPathComponent("DisplaySwitch.store")

    let modelConfiguration = ModelConfiguration(schema: schema, url: fileURL)

    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

      for usage in KeybindUsage.allCases {
        let rawUsage = usage.rawValue
        var descriptor = FetchDescriptor<Keybind>(predicate: #Predicate { $0.usage == rawUsage })
        descriptor.fetchLimit = 1

        let existingCount = (try? container.mainContext.fetch(descriptor))?.count ?? 0
        if existingCount == 0 {
          container.mainContext.insert(Keybind(usage))
        }
      }

      try! container.mainContext.save()

      return container
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    MenuBarExtra("DisplaySwitch", systemImage: "power.circle.fill") {
      ContentView()
        .modelContainer(self.sharedModelContainer)
    }
    .menuBarExtraStyle(.window)
    .menuBarExtraAccess(isPresented: self.$openMenuBar)
    .onChange(of: self.appDelegate.openMenuBar) { _, newValue in
      self.$openMenuBar.wrappedValue = newValue
    }
    Window("DisplaySwitch Settings", id: "settings") {
      SettingsView()
        .modelContainer(self.sharedModelContainer)
        .frame(minWidth: 400, minHeight: 280)
    }
  }
}
