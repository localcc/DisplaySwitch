import SwiftUI

@MainActor
@Observable
class AppKeyboardListener {
  var lastEvent: NSEvent?

  private var monitor: Any?

  init() {
    // yeah monitor leaks but this is a singleton
    // and deinit can be called from non-main thread contexts
    monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown, .flagsChanged]) { event in
      self.lastEvent = event
      return event
    }
  }

  static let shared = AppKeyboardListener()
}
