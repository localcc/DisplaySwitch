import Foundation
import SwiftUI

extension View {
  func conditional<M: ViewModifier>(on condition: Bool, _ modifier: M) -> some View {
    Group {
      if condition {
        self.modifier(modifier)
      } else {
        self
      }
    }
  }
}
