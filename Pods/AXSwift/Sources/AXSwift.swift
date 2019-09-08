@discardableResult
public func checkIsProcessTrusted(prompt: Bool = false) -> Bool {
    let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let opts = [promptKey: prompt] as CFDictionary
    return AXIsProcessTrustedWithOptions(opts)
}
