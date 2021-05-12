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

func stringColor(colorString: String) -> NSColor {
    let components =  colorString.split(separator: " ")
    return NSColor(red: CGFloat((components[0] as NSString).doubleValue),
                green: CGFloat((components[1] as NSString).doubleValue),
                blue: CGFloat((components[2] as NSString).doubleValue),
                alpha: CGFloat((components[3] as NSString).doubleValue) )
}
func colorString(color: NSColor) -> String {
    return String(format: "%f %f %f %f", color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent)
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

        class HintColorProperty : PreferenceProperty {

            typealias T = String

            static var key = "HintColor"

            static var defaultValue = colorString(color: UserDefaultsProperties.hintColor.read())

            static func readColor() -> NSColor {
                let string = read()
                return stringColor(colorString: string)
            }

            static func saveColor(value: NSColor) {
                self.save(value: colorString(color: value))
            }

            static func isValid(value: String) -> Bool {
                return true
            }

        }
    }
    
    struct ScrollMode {
        class ScrollKeysProperty : PreferenceProperty {
            typealias T = String
            
            static var key = "ScrollCharacters"
            static var defaultValue = "h,j,k,l,d,u,G,gg"
            
            static func isValid(value keys: String) -> Bool {
                let keySequences = keys.components(separatedBy: ",")
                let isCountValid = keySequences.count == 4 || keySequences.count == 6 || keySequences.count == 8
                let areKeySequencesUnique = keySequences.count == Set(keySequences).count
                return isCountValid && areKeySequencesUnique
            }
            
            static func readAsConfig() -> ScrollKeyConfig {
                let s = read()
                let keySequences = s.components(separatedBy: ",")
                let scrollLeftKey = keySequences[0]
                let scrollDownKey = keySequences[1]
                let scrollUpKey = keySequences[2]
                let scrollRightKey = keySequences[3]
                let scrollHalfDownKey = keySequences.count >= 6 ? (keySequences[4]) : nil
                let scrollHalfUpKey = keySequences.count >= 6 ? (keySequences[5]) : nil
                let scrollBottomKey = keySequences.count >= 8 ? keySequences[6] : nil
                let scrollTopKey = keySequences.count >= 8 ? keySequences[7] : nil
                
                var bindings: [ScrollKeyConfig.Binding] = [
                    .init(keys: Array(scrollLeftKey), direction: .left),
                    .init(keys: Array(scrollDownKey), direction: .down),
                    .init(keys: Array(scrollUpKey), direction: .up),
                    .init(keys: Array(scrollRightKey), direction: .right),
                    
                    .init(keys: Array(scrollLeftKey.uppercased()), direction: .halfLeft),
                    .init(keys: Array(scrollDownKey.uppercased()), direction: .halfDown),
                    .init(keys: Array(scrollUpKey.uppercased()), direction: .halfUp),
                    .init(keys: Array(scrollRightKey.uppercased()), direction: .halfRight),
                ]
                
                if let k = scrollHalfDownKey {
                    bindings.append(
                        .init(keys: Array(k), direction: .halfDown)
                    )
                }
                
                if let k = scrollHalfUpKey {
                    bindings.append(
                        .init(keys: Array(k), direction: .halfUp)
                    )
                }
                
                if let k = scrollBottomKey {
                    bindings.append(
                        .init(keys: Array(k), direction: .bottom)
                    )
                }
                
                if let k = scrollTopKey {
                    bindings.append(
                        .init(keys: Array(k), direction: .top)
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

        class ScrollFrameColorProperty : PreferenceProperty {

            typealias T = String

            static var key = "ScrollColor"

            static var defaultValue = colorString(color: UserDefaultsProperties.scrollFrameColor.read())

            static func readColor() -> NSColor {
                let string = read()
                return stringColor(colorString: string)
            }

            static func saveColor(value: NSColor) {
                self.save(value: colorString(color: value))
            }

            static func isValid(value: String) -> Bool {
                return true
            }

        }

    }
}
