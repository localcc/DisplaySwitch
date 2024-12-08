import AppKit
import SwiftData

enum KeybindUsage: Int, CaseIterable, Hashable, Codable {
  /// Disable display that the cursor is currently on
  case activeDisplay
}

@Model
class Keybind {
  @Attribute(.unique) var usage: Int
  var mainKeyCode: UInt16?
  var mainKey: String?
  var modifiers: UInt = UInt()

  var nsModifiers: NSEvent.ModifierFlags {
    get { NSEvent.ModifierFlags(rawValue: self.modifiers) }
    set { self.modifiers = newValue.rawValue }
  }

  init(_ usage: KeybindUsage) {
    self.usage = usage.rawValue
  }

  init(usage: Int, mainKeyCode: UInt16?, mainKey: String?, modifiers: UInt) {
    self.usage = usage
    self.mainKeyCode = mainKeyCode
    self.mainKey = mainKey
    self.modifiers = modifiers
  }

  func clear() {
    self.mainKeyCode = nil
    self.mainKey = nil
    self.modifiers = .init()
  }
}

extension Keybind {
  func toDTO() -> KeybindDTO {
    KeybindDTO(usage: self.usage, mainKeyCode: self.mainKeyCode, mainKey: self.mainKey, modifiers: self.modifiers)
  }

  static func fromDTO(dto: KeybindDTO) -> Keybind {
    Keybind(usage: dto.usage, mainKeyCode: dto.mainKeyCode, mainKey: dto.mainKey, modifiers: dto.modifiers)
  }
}

final class KeybindDTO: Sendable, Identifiable {
  let usage: Int
  let mainKeyCode: UInt16?
  let mainKey: String?
  let modifiers: UInt

  var nsModifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: self.modifiers) }

  init(usage: Int, mainKeyCode: UInt16?, mainKey: String?, modifiers: UInt) {
    self.usage = usage
    self.mainKeyCode = mainKeyCode
    self.mainKey = mainKey
    self.modifiers = modifiers
  }

  func matches(event: NSEvent) -> Bool {
    guard let mainKeyCode = self.mainKeyCode else {
      return false
    }

    return mainKeyCode == event.keyCode && self.nsModifiers == event.modifierFlags
  }
}
