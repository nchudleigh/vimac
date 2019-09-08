# AXSwift

[![Version](https://cocoapod-badges.herokuapp.com/v/AXSwift/badge.svg)](http://cocoadocs.org/pods/AXSwift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

AXSwift is a Swift wrapper for macOS's C-based accessibility client APIs. Working with these APIs is
error-prone and a huge pain, so AXSwift makes everything easier:

- Modern API that's 100% Swift
- Explicit error handling
- Complete coverage of the underlying C API
- Better documentation than Apple's, which is pretty poor

This framework is intended as a basic wrapper, and doesn't keep any state or do any "magic".
That's up to you!

## Using AXSwift

Swift package manager (SPM) is not supported, because it cannot build libraries
and applications that depend on Cocoa.

### Carthage
In your Cartfile:
```
github "tmandry/AXSwift" ~> 0.2
```

### CocoaPods
In your Podfile:
```
pod 'AXSwift', '~> 0.2'
```

See the source of [AXSwiftExample](https://github.com/tmandry/AXSwift/blob/master/AXSwiftExample/AppDelegate.swift)
and [AXSwiftObserverExample](https://github.com/tmandry/AXSwift/blob/master/AXSwiftObserverExample/AppDelegate.swift)
for an example of the API.

## Related Projects

[Swindler](https://github.com/tmandry/Swindler), a framework for building macOS window managers in Swift,
is built on top of AXSwift.
