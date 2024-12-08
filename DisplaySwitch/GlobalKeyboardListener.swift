import AppKit
import Quartz
import SwiftData
import SwiftUI

extension NSScreen {
  static func screenWithMouse() -> NSScreen? {
    let mouseLocation = NSEvent.mouseLocation
    let screens = NSScreen.screens
    let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })

    return screenWithMouse
  }
}

struct CallbackData {
  var lastModifierFlags: NSEvent.ModifierFlags = .init()
  var lastFlagsEventTime: Date? = nil
  var consecutiveCmdPresses = 0
}

@Observable
class GlobalKeyboardListener: @unchecked Sendable {
  var bindsEnabled: Bool = true
  var modelContainer: ModelContainer
  var accessibilityEnabled: Bool = false

  var displays: [DisplayDTO] = []
  var keyBindings: [KeybindDTO] = []

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer

    NotificationCenter.default.addObserver(self, selector: #selector(self.refreshBinds), name: .NSPersistentStoreRemoteChange, object: nil)
    self.refreshBinds()
  }

  func initializeTaps() -> Bool {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
    self.accessibilityEnabled = AXIsProcessTrustedWithOptions(options)

    if !self.accessibilityEnabled {
      return true
    }

    var data = CallbackData()
    let ptr = UnsafeMutablePointer<CallbackData>.allocate(capacity: 1)
    ptr.initialize(from: &data, count: 1)

    guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue | 1 << CGEventType.flagsChanged.rawValue), callback: CGEventCallback, userInfo: ptr) else {
      return false
    }

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)

    return true
  }

  @objc func refreshBinds() {
    Task {
      await self.refreshBindsAsync()
    }
  }

  func refreshBindsAsync() async {
    let modelActor = DataModelActor(modelContainer: self.modelContainer)
    self.displays = (try? await modelActor.allDisplays()) ?? []
    self.keyBindings = (try? await modelActor.allKeybinds()) ?? []
  }

  func checkBinds(for event: NSEvent) -> Bool {
    if !self.bindsEnabled {
      return false
    }

    for bind in self.keyBindings {
      if bind.matches(event: event) {
        Task {
          await self.executeBind(KeybindUsage(rawValue: bind.usage)!)
        }
        return true
      }
    }
    return false
  }

  func executeBind(_ usage: KeybindUsage) async {
    switch usage {
    case KeybindUsage.activeDisplay:
      guard let screen = NSScreen.screenWithMouse() else {
        return
      }

      guard let displayId = screen.displayID else {
        return
      }

      guard let display = self.displays.filter({ $0.displayId == displayId }).first else {
        return
      }

      let modelActor = DataModelActor(modelContainer: self.modelContainer)
      if let disabledDisplay = try? await modelActor.setEnabled(display, enabled: false) {
        _ = try? await DisplayController.instance.update(display: disabledDisplay)
      }
    }
  }

  func panicKeybind() async {
    Task {
      _ = try? await DisplayController.instance.connectAll()
    }
  }

  public nonisolated(unsafe) static var initializedInstance: GlobalKeyboardListener?
  public static var shared: GlobalKeyboardListener { initializedInstance! }
}

func CGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
  guard let ptr = refcon else {
    return Unmanaged.passRetained(event)
  }
  let callbackDataPtr = ptr.bindMemory(to: CallbackData.self, capacity: 1)

  if type == CGEventType.keyDown {
    if let nsEvent = NSEvent(cgEvent: event) {
      if !nsEvent.isARepeat {
        if GlobalKeyboardListener.shared.checkBinds(for: nsEvent) {
          return nil
        }
      }
    }
  }

  if type == CGEventType.flagsChanged {
    let now = Date()
    if let nsEvent = NSEvent(cgEvent: event) {
      let timeOkay = callbackDataPtr.pointee.lastFlagsEventTime != nil ? callbackDataPtr.pointee.lastFlagsEventTime!.distance(to: now) < 0.4 : true
      let cmdPressed = nsEvent.modifierFlags.contains(.command)
      let othersPressed = nsEvent.modifierFlags.contains(.shift) || nsEvent.modifierFlags.contains(.option) || nsEvent.modifierFlags.contains(.control)

      if timeOkay && cmdPressed && !othersPressed {
        callbackDataPtr.pointee.consecutiveCmdPresses += 1
        if callbackDataPtr.pointee.consecutiveCmdPresses >= 5 {
          Task {
            await GlobalKeyboardListener.shared.panicKeybind()
          }
          callbackDataPtr.pointee.consecutiveCmdPresses = 0
        }
      } else if !timeOkay || othersPressed {
        callbackDataPtr.pointee.consecutiveCmdPresses = 0
      }

      callbackDataPtr.pointee.lastModifierFlags = nsEvent.modifierFlags
    }

    callbackDataPtr.pointee.lastFlagsEventTime = now
  }
  return Unmanaged.passRetained(event)
}
