import AppKit
import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarItem: NSStatusItem?
  private var window: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
    statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = statusBarItem?.button {
      button.action = #selector(statusBarButtonClicked(_:))
      button.target = self
      button.image = NSImage(systemSymbolName: "gamecontroller.fill", accessibilityDescription: "Amogis")
      button.title = "Amogis"
    }
  }

  @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {}

  @MainActor
  func getOrbuildWindow(size: NSRect) -> NSWindow {
    if window != nil {
      return window!
    }

    let contentView = ContentView()
    let window = NSWindow(contentRect: size, styleMask: [.borderless], backing: .buffered, defer: false)
    window.contentView = NSHostingView(rootView: contentView)
    window.isReleasedWhenClosed = false
    window.collectionBehavior = .moveToActiveSpace
    window.level = .floating
    self.window = window

    return window
  }

  @MainActor
  func toggleWindowVisibility(location: NSPoint) {
    if window == nil {
      return
    }

    if window!.isVisible {
      window!.orderOut(nil)
    } else {
      window!.setFrameOrigin(location)
      window!.makeKeyAndOrderFront(nil)
      NSApp.activate()
    }
  }
}
