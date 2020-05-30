import Cocoa
import Preferences

final class HintModePreferenceViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.hintMode
    let preferencePaneTitle = "Hint Mode"

    override var nibName: NSNib.Name? { "HintModePreferenceViewController" }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
