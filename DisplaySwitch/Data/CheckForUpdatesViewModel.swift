import Sparkle
import SwiftUI

@MainActor
final class Updater: ObservableObject {
  var updater: SPUUpdater
  @Published var canCheckForUpdates: Bool = false

  init(updater: SPUUpdater) {
    self.updater = updater
    updater.publisher(for: \.canCheckForUpdates)
      .assign(to: &$canCheckForUpdates)
  }

  public nonisolated(unsafe) static var initializedInstance: Updater?
  public static var shared: Updater { initializedInstance! }
}
