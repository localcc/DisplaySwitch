import Foundation
import ServiceManagement

final class LaunchAtStartup: Sendable {
  let isEnabled: Bool

  init() {
    var enabled = false
    do {
      try SMAppService.mainApp.register()
      enabled = true
    } catch let err as NSError {
      if err.code == kSMErrorAlreadyRegistered, SMAppService.mainApp.status == .enabled {
        enabled = true
      }
    }

    self.isEnabled = enabled
  }

  static let shared = LaunchAtStartup()
}
