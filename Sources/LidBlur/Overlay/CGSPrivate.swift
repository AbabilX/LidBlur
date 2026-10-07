import Foundation

// Private WindowServer (CoreGraphics Services) calls.
//
// AppKit's public blur (NSVisualEffectView) has a fixed strength, so the variable
// blur radius comes from these. They are undocumented and may change between
// macOS releases; keep every private symbol the app uses in this file.

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> Int32

@_silgen_name("CGSSetWindowBackgroundBlurRadius")
func CGSSetWindowBackgroundBlurRadius(_ connection: Int32, _ window: Int32, _ radius: Int32) -> Int32
