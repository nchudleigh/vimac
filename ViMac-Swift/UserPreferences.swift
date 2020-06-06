import Cocoa
import RxCocoa
import RxSwift

protocol PreferenceProperty {
    associatedtype T
    
    static var key: String { get }
    static var defaultValue: T { get }
    
    static func isValid(value: T) -> Bool
    static func parseRaw(rawValue: String) -> T?
}

extension PreferenceProperty {
    static func isRawValid(rawValue: String) -> Bool {
        return parseRaw(rawValue: rawValue) != nil
    }
    
    static func saveRaw(rawValue: String) {
        UserDefaults.standard.set(rawValue, forKey: key)
    }

    static func readRaw() -> String {
        return UserDefaults.standard.string(forKey: key) ?? ""
    }

    static func readUnvalidated() -> T? {
        return parseRaw(rawValue: readRaw())
    }
 
    static func read() -> T {
        let unvalidatedValueWeak = readUnvalidated()
        
        guard let unvalidatedValue = unvalidatedValueWeak else {
            return defaultValue
        }
        
        return isValid(value: unvalidatedValue) ? unvalidatedValue : defaultValue
    }
}

struct UserPreferences {
    struct HintMode {
        class CustomCharactersProperty : PreferenceProperty {
            typealias T = String
            
            static var key = "HintCharacters"
            static var defaultValue = "sadfjklewcmpgh"
            
            static func isValid(value characters: String) -> Bool {
                let minAllowedCharacters = 10
                let isEqOrMoreThanMinChars = characters.count >= minAllowedCharacters
                let areCharsUnique = characters.count == Set(characters).count
                return isEqOrMoreThanMinChars && areCharsUnique
            }
            
            static func parseRaw(rawValue: String) -> String? {
                return rawValue
            }
        }
        
        class TextSizeProperty : PreferenceProperty {
            typealias T = Float
            
            static var key = "HintTextSize"
            static var defaultValue: Float = 11.0
            
            static func isValid(value size: Float) -> Bool {
                return size > 0 && size <= 100
            }
            
            static func parseRaw(rawValue: String) -> Float? {
                return Float(rawValue)
            }
        }
    }
}
