import AppKit
import CoreGraphics
import Foundation
import SwiftData
import SwiftUI

extension NSScreen {
  var displayID: CGDirectDisplayID? {
    return deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
  }
}

enum DisplayControllerError: Error {
  case reconfigureCallbackRegister(CGError)
  case failedToBeginConfig(CGError)
  case failedToCompleteConfig(CGError)
  case failedToEnumerateDisplays(CGError)
}

extension DisplayControllerError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .reconfigureCallbackRegister(let err):
      return String(format: NSLocalizedString("Failed to register CoreGraphics display update callbacks. Displays that are reconnected may not be detected. CGError: %@", comment: ""), "\(err.rawValue)")
    case .failedToBeginConfig(let err):
      return String(format: NSLocalizedString("failed to begin config, CGError: %@", comment: ""), "\(err.rawValue)")
    case .failedToCompleteConfig(let err):
      return String(format: NSLocalizedString("failed to complete config, CGError: %@", comment: ""), "\(err.rawValue)")
    case .failedToEnumerateDisplays(let err):
      return String(format: NSLocalizedString("failed to enumerate displays, CGError: %@", comment: ""), "\(err.rawValue)")
    }
  }
}

func reconfigurationCallback(displayId: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags, userInfo: UnsafeMutableRawPointer?) {
  if !flags.contains(.addFlag) {
    return
  }
  Task {
    await DisplayController.instance.updateAvailableDisplays()
  }
}

actor DisplayController {
  public static var initializedInstance: DisplayController?

  public static var instance: DisplayController {
    return initializedInstance!
  }

  public var modelContainer: ModelContainer

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }

  public func initializeCallbacks() async throws {
    let err = CGDisplayRegisterReconfigurationCallback(reconfigurationCallback, nil)
    guard err == .success else {
      throw DisplayControllerError.reconfigureCallbackRegister(err)
    }

    Task {
      await refreshDisplays()
    }
  }

  public func update(display: DisplayDTO) throws {
    try DisplayController.configCoreGraphics { config in
      SLSConfigureDisplayEnabled(config, display.displayId, display.enabled)
    }
  }

  public func updateAvailableDisplays(clearDisconnected: Bool = false) async {
    let modelActor = DataModelActor(modelContainer: modelContainer)
    let displays = connectedDisplays()

    if clearDisconnected {
      try? await modelActor.clearDisplays()
    }

    for display in displays {
      _ = try? await modelActor.insert(display: display)
    }
  }

  public func refreshDisplays(clearDisconnected: Bool = false) async {
    await updateAvailableDisplays(clearDisconnected: clearDisconnected)

    let modelActor = DataModelActor(modelContainer: modelContainer)
    let displays = (try? await modelActor.allDisplays()) ?? []
    for display in displays {
      _ = try? update(display: display)
    }
  }

  public func connectAll() async throws {
    var displays = Array(repeating: CGDirectDisplayID(), count: 16)
    var listCount = UInt32(0)
    let err = SLSGetDisplayList(UInt32(displays.count), &displays, &listCount)
    guard err == .success else {
      throw DisplayControllerError.failedToEnumerateDisplays(err)
    }

    for listIndex in 0 ..< Int(listCount) {
      _ = try? DisplayController.configCoreGraphics { config in
        SLSConfigureDisplayEnabled(config, displays[listIndex], true)
      }
    }

    let modelActor = DataModelActor(modelContainer: modelContainer)
    let modelDisplays = (try? await modelActor.allDisplays()) ?? []
    for display in modelDisplays {
      _ = try? await modelActor.setEnabled(display, enabled: true)
    }
  }

  private func connectedDisplays() -> [DisplayDTO] {
    let screens = NSScreen.screens
    return screens
      .filter { $0.displayID != nil }
      .map { DisplayDTO(name: $0.localizedName, displayId: $0.displayID!, enabled: true) }
  }

  private static func configCoreGraphics(_ action: (CGDisplayConfigRef) throws -> Void) throws {
    var configRef: CGDisplayConfigRef?
    var err = CGBeginDisplayConfiguration(&configRef)
    guard err == .success, let config = configRef else {
      throw DisplayControllerError.failedToBeginConfig(err)
    }

    do {
      try action(config)
    } catch let err {
      _ = CGCancelDisplayConfiguration(config)
      throw err
    }

    err = CGCompleteDisplayConfiguration(config, .forSession)
    guard err == .success else {
      _ = CGCancelDisplayConfiguration(config)
      throw DisplayControllerError.failedToCompleteConfig(err)
    }
  }
}
