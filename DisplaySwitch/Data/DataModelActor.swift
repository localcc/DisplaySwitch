import SwiftData

@ModelActor
actor DataModelActor {
  func insert(display: DisplayDTO) async throws {
    modelContext.insert(Display.fromDTO(dto: display))
    try modelContext.save()
  }

  func findDisplay(id: CGDirectDisplayID) async throws -> DisplayDTO? {
    var fetchDescriptor = FetchDescriptor<Display>(predicate: #Predicate { $0.displayId == id })
    fetchDescriptor.fetchLimit = 1

    let display = try modelContext.fetch(fetchDescriptor).first

    return display.map { $0.toDTO() }
  }

  func allDisplays() async throws -> [DisplayDTO] {
    let fetchDescriptor = FetchDescriptor<Display>()
    return try modelContext.fetch(fetchDescriptor).map { $0.toDTO() }
  }

  func setEnabled(_ dto: DisplayDTO, enabled: Bool) async throws -> DisplayDTO {
    let model = Display(name: dto.name, displayId: dto.displayId, enabled: enabled)
    modelContext.insert(model)
    try modelContext.save()
    return model.toDTO()
  }

  func clearDisplays() async throws {
    try modelContext.delete(model: Display.self)
    try modelContext.save()
  }

  func allKeybinds() async throws -> [KeybindDTO] {
    let fetchDescriptor = FetchDescriptor<Keybind>()
    return try modelContext.fetch(fetchDescriptor).map { $0.toDTO() }
  }
}
