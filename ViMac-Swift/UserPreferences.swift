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
                let minAllowedCharacters = 6
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
        
        class TextOffsetProperty : PreferenceProperty {
            typealias T = String
            
            static var key = "HintOffsetSize"
            static var defaultValue = "0, 0"
            
            static func isValid(value: String) -> Bool {
                
                let numbers = value.components(separatedBy: ",")
                    .lazy
                    .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .compactMap { Float($0) }
                    .compactMap { CGFloat($0) }
                
                return numbers.count >= 2
            }
            
            static func readAsPoint() -> CGPoint {
                
                let numbers = read().components(separatedBy: ",")
                    .lazy
                    .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .compactMap { Float($0) }
                    .compactMap { CGFloat($0) }
                
                return CGPoint(x: numbers[0], y: numbers[1])
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
            
            static func readAsConfig() -> ScrollKeyConfig {
                let s = read()
                
                let scrollLeftKey = s[s.index(s.startIndex, offsetBy: 0)]
                let scrollDownKey = s[s.index(s.startIndex, offsetBy: 1)]
                let scrollUpKey = s[s.index(s.startIndex, offsetBy: 2)]
                let scrollRightKey = s[s.index(s.startIndex, offsetBy: 3)]
                let scrollHalfDownKey = s.count == 6 ? (s[s.index(s.startIndex, offsetBy: 4)]) : nil
                let scrollHalfUpKey = s.count == 6 ? (s[s.index(s.startIndex, offsetBy: 5)]) : nil
                
                var bindings: [ScrollKeyConfig.Binding] = [
                    .init(keys: [scrollLeftKey], direction: .left),
                    .init(keys: [scrollDownKey], direction: .down),
                    .init(keys: [scrollUpKey], direction: .up),
                    .init(keys: [scrollRightKey], direction: .right),
                    
                    .init(keys: [Character(scrollLeftKey.uppercased())], direction: .halfLeft),
                    .init(keys: [Character(scrollDownKey.uppercased())], direction: .halfDown),
                    .init(keys: [Character(scrollUpKey.uppercased())], direction: .halfUp),
                    .init(keys: [Character(scrollRightKey.uppercased())], direction: .halfRight),
                ]
                
                if let k = scrollHalfDownKey {
                    bindings.append(
                        .init(keys: [k], direction: .halfDown)
                    )
                }
                
                if let k = scrollHalfUpKey {
                    bindings.append(
                        .init(keys: [k], direction: .halfUp)
                    )
                }
                
                return ScrollKeyConfig(bindings: bindings)
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
