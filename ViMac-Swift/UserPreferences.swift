import Cocoa
import RxCocoa
import RxSwift

struct UserPreferences {
    struct HintMode {
        static let hintCharactersKey = "HintCharacters"
        static let defaultHintCharacters = "sadfjklewcmpgh"
        static let customCharacters = UserDefaults.standard.rx.observe(String.self, hintCharactersKey)
            .map({ mapInvalidCustomCharacters(weak: $0) })
        
        static func readCustomCharactersRaw() -> String {
            return UserDefaults.standard.string(forKey: hintCharactersKey) ?? ""
        }
        
        static func readCustomCharacters() -> String {
            return mapInvalidCustomCharacters(weak: readCustomCharactersRaw())
        }
        
        static func saveCustomCharacters(characters: String) {
            UserDefaults.standard.set(characters, forKey: hintCharactersKey)
        }
        
        static func mapInvalidCustomCharacters(weak: String?) -> String {
            guard let strong = weak else {
                return defaultHintCharacters
            }
            
            return isCustomCharactersValid(characters: strong) ? strong : defaultHintCharacters
        }

        static func isCustomCharactersValid(characters: String) -> Bool {
            let minAllowedCharacters = 10
            let isEqOrMoreThanMinChars = characters.count >= minAllowedCharacters
            let areCharsUnique = characters.count == Set(characters).count
            return isEqOrMoreThanMinChars && areCharsUnique
        }
        
        static let hintTextSizeKey = "HintTextSize"
        static let defaultHintTextSize: Float = 11.0
        static let textSize = UserDefaults.standard.rx.observe(Float.self, hintTextSizeKey)
            .map({ mapInvalidHintSize(weak: $0) })
        
        static func readHintSizeRaw() -> String {
            return UserDefaults.standard.string(forKey: hintTextSizeKey) ?? ""
        }
        
        static func readHintSize() -> Float {
            let raw = readHintSizeRaw()
            return mapInvalidHintSize(weak: Float(raw))
        }
        
        static func saveTextSize(size: String) {
            UserDefaults.standard.set(size, forKey: hintTextSizeKey)
        }
        
        static func isRawHintSizeValid(sizeRaw: String) -> Bool {
            guard let size = Float(sizeRaw) else {
                return false
            }
            
            return isHintSizeValid(size: size)
        }
        
        static func isHintSizeValid(size: Float) -> Bool {
            return size > 0 && size <= 100
        }
        
        static func mapInvalidHintSize(weak: Float?) -> Float {
            guard let strong = weak else {
                return defaultHintTextSize
            }
            
            return isHintSizeValid(size: strong) ? strong : defaultHintTextSize
        }
    }
}
