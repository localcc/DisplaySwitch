import AppKit
import SwiftUI

class KeybindTextField: NSTextField {
  var onFocus: () -> Void = {}

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func becomeFirstResponder() -> Bool {
    onFocus()
    return super.becomeFirstResponder()
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    return true
  }
}

struct KeybindButtonTextField: NSViewRepresentable {
  @Binding var hasFocus: Bool
  var text: String
  var placeholderText: String

  init(hasFocus: Binding<Bool>, text: String, placeholderText: String = "") {
    self._hasFocus = hasFocus
    self.text = text
    self.placeholderText = placeholderText
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  func makeNSView(context: Context) -> KeybindTextField {
    let textField = KeybindTextField()
    textField.bezelStyle = .roundedBezel
    textField.placeholderString = placeholderText
    textField.delegate = context.coordinator
    textField.alignment = .center
    textField.window?.delegate = context.coordinator
    textField.focusRingType = .exterior
    textField.onFocus = {
      DispatchQueue.main.async {
        self.hasFocus = true
      }
    }

    return textField
  }

  func updateNSView(_ nsView: KeybindTextField, context: Context) {
    nsView.placeholderString = placeholderText
    nsView.stringValue = text
  }

  class Coordinator: NSObject, NSWindowDelegate, NSTextFieldDelegate {
    let parent: KeybindButtonTextField

    init(_ parent: KeybindButtonTextField) {
      self.parent = parent
    }

    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
      DispatchQueue.main.async {
        self.parent.hasFocus = true
      }
      return false
    }
  }
}

struct KeybindInput: View {
  @FocusState var isFocused: Bool

  @Environment(\.modelContext) var modelContext
  @Bindable var bind: Keybind
  @Bindable var appListener: AppKeyboardListener = .shared

  @State var firstPress: Bool = true
  @State var hasFocus: Bool = false

  // Fix the autofocus focusing this keybind field on page open
  @State private var disabled: Bool = true

  var text: String {
    (bind.nsModifiers.contains(.command) ? "⌘" : "") +
      (bind.nsModifiers.contains(.control) ? "⌃" : "") +
      (bind.nsModifiers.contains(.shift) ? "⇧" : "") +
      (bind.mainKey ?? "")
  }

  func hasModifiers() -> Bool {
    bind.nsModifiers.contains(.option) || bind.nsModifiers.contains(.shift) || bind.nsModifiers.contains(.command) || bind.nsModifiers.contains(.control)
  }

  func checkFirstPress() {
    if firstPress {
      bind.clear()
      firstPress = false
    }
  }

  var body: some View {
    HStack {
      KeybindButtonTextField(hasFocus: $hasFocus, text: text, placeholderText: hasFocus ? "Recording" : "Press to record")
        .frame(maxWidth: 140)
        .onChange(of: hasFocus) { _, newValue in
          GlobalKeyboardListener.shared.bindsEnabled = !newValue
        }
        .onChange(of: appListener.lastEvent) { _, event in
          if !hasFocus {
            return
          }
          guard let event = event else {
            return
          }

          if event.type == .keyDown {
            checkFirstPress()
            let character = event.charactersIgnoringModifiers?.uppercased()
            if let character = character {
              if !character.isEmpty {
                bind.mainKeyCode = event.keyCode
                bind.mainKey = character
                bind.nsModifiers = event.modifierFlags

                if hasModifiers() {
                  DispatchQueue.main.async {
                    hasFocus = false
                    firstPress = true
                    _ = try? modelContext.save()
                    NSApp.keyWindow?.makeFirstResponder(nil)
                  }
                }
              }
            }
          } else if event.type == .keyUp {
            if !hasModifiers() {
              bind.clear()
            }
          } else if event.type == .flagsChanged {
            checkFirstPress()
            bind.nsModifiers = event.modifierFlags
          }
        }
      Button {
        bind.clear()

        DispatchQueue.main.async {
          hasFocus = false
          NSApp.keyWindow?.makeFirstResponder(nil)
        }
      } label: {
        Image(systemName: "xmark.circle.fill")
      }
      .padding([.trailing], 8)
      .buttonStyle(.plain)
    }
    .disabled(disabled)
    .onAppear {
      DispatchQueue.main.async {
        disabled = false
      }
    }
  }
}
