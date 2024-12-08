import CoreGraphics
import SwiftData

@Model
class Display: Hashable {
  var name: String
  @Attribute(.unique) var displayId: CGDirectDisplayID
  var enabled: Bool

  init(name: String, displayId: CGDirectDisplayID, enabled: Bool) {
    self.name = name
    self.displayId = displayId
    self.enabled = enabled
  }
}

extension Display {
  func toDTO() -> DisplayDTO {
    DisplayDTO(name: self.name, displayId: self.displayId, enabled: self.enabled)
  }

  static func fromDTO(dto: DisplayDTO) -> Display {
    Display(name: dto.name, displayId: dto.displayId, enabled: dto.enabled)
  }
}

final class DisplayDTO: Sendable, Identifiable {
  let id: PersistentIdentifier?
  let name: String
  let displayId: CGDirectDisplayID
  let enabled: Bool

  init(id: PersistentIdentifier, name: String, displayId: CGDirectDisplayID, enabled: Bool) {
    self.id = id
    self.name = name
    self.displayId = displayId
    self.enabled = enabled
  }

  init(name: String, displayId: CGDirectDisplayID, enabled: Bool) {
    self.id = nil
    self.name = name
    self.displayId = displayId
    self.enabled = enabled
  }
}
