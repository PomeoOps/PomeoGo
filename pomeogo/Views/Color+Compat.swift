import SwiftUI

#if os(macOS)
let groupBgColor = Color(NSColor.windowBackgroundColor)
let secondaryGroupBgColor = Color(NSColor.controlBackgroundColor)
let controlBgColor = Color(NSColor.controlBackgroundColor)
let textBgColor = Color(NSColor.textBackgroundColor)
let unemphasizedSelectedContentBgColor = Color(NSColor.unemphasizedSelectedContentBackgroundColor)
#else
let groupBgColor = Color(UIColor.systemGroupedBackground)
let secondaryGroupBgColor = Color(UIColor.secondarySystemGroupedBackground)
let controlBgColor = Color(UIColor.systemBackground)
let textBgColor = Color(UIColor.systemBackground)
let unemphasizedSelectedContentBgColor = Color(UIColor.systemGray5)
#endif 