import Foundation

extension AXError: Swift.Error {}

// For some reason values don't get described in this enum, so we have to do it manually.
extension AXError: CustomStringConvertible {
    fileprivate var valueAsString: String {
        switch self {
        case .success:
            return "Success"
        case .failure:
            return "Failure"
        case .illegalArgument:
            return "IllegalArgument"
        case .invalidUIElement:
            return "InvalidUIElement"
        case .invalidUIElementObserver:
            return "InvalidUIElementObserver"
        case .cannotComplete:
            return "CannotComplete"
        case .attributeUnsupported:
            return "AttributeUnsupported"
        case .actionUnsupported:
            return "ActionUnsupported"
        case .notificationUnsupported:
            return "NotificationUnsupported"
        case .notImplemented:
            return "NotImplemented"
        case .notificationAlreadyRegistered:
            return "NotificationAlreadyRegistered"
        case .notificationNotRegistered:
            return "NotificationNotRegistered"
        case .apiDisabled:
            return "APIDisabled"
        case .noValue:
            return "NoValue"
        case .parameterizedAttributeUnsupported:
            return "ParameterizedAttributeUnsupported"
        case .notEnoughPrecision:
            return "NotEnoughPrecision"
        }
    }

    public var description: String {
        return "AXError.\(valueAsString)"
    }
}

/// All possible errors that could be returned from UIElement or one of its subclasses.
///
/// These are just the errors that can be returned from the underlying API.
///
/// - seeAlso: [AXUIElement.h Reference](https://developer.apple.com/library/mac/documentation/ApplicationServices/Reference/AXUIElement_header_reference/)
/// - seeAlso: `UIElement` for a list of errors that you should handle
//public typealias Error = AXError
