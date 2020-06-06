import Cocoa
import RxCocoa
import RxSwift

protocol PreferenceProperty {
    associatedtype T
    
    static var key: String { get }
    static var defaultValue: T { get }
    
    static func isValid(value: T) -> Bool
}

extension PreferenceProperty {
    static func save(value: T) {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func readUnvalidated() -> T? {
        let invalidValue = (UserDefaults.standard.value(forKey: key) as? T?)?.flatMap({ $0 })
        return invalidValue
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
        }
        
        class TextSizeProperty : PreferenceProperty {
            typealias T = String
            
            static var key = "HintTextSize"
            static var defaultValue = "11.0"
            
            static func isValid(value: String) -> Bool {
                let floatValueMaybe = Float(value)
                
                guard let floatValue = floatValueMaybe else {
                    return false
                }
                
                return floatValue > 0 && floatValue <= 100
            }
            
            static func readAsFloat() -> Float {
                return Float(read())!
            }
        }
    }
    
    struct ScrollMode {
        class ScrollKeysProperty : PreferenceProperty {
            typealias T = String
            
            static var key = "ScrollCharacters"
            static var defaultValue = "hjkldu"
            
            static func isValid(value keys: String) -> Bool {
                let isCountValid = keys.count == 4 || keys.count == 6
                let areKeysUnique = keys.count == Set(keys).count
                return isCountValid && areKeysUnique
            }
        }
        
        class ScrollSensitivityProperty : PreferenceProperty {
            typealias T = Int
            
            static var key = "ScrollSensitivity"
            static var defaultValue = 20
            
            static func isValid(value sensitivity: Int) -> Bool {
                return sensitivity >= 0 && sensitivity <= 100
            }
        }
        
        class ReverseHorizontalScrollProperty : PreferenceProperty {
            typealias T = Bool
            
            static var key = "IsHorizontalScrollReversed"
            static var defaultValue = false
            
            static func isValid(value: Bool) -> Bool {
                return true
            }
        }
        
        class ReverseVerticalScrollProperty : PreferenceProperty {
            typealias T = Bool
            
            static var key = "IsVerticalScrollReversed"
            static var defaultValue = false
            
            static func isValid(value: Bool) -> Bool {
                return true
            }
        }
    }
}
