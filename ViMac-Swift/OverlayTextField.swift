//
//  OverlayTextField.swift
//  ViMac-Swift
//
//  Created by Huawei Matebook X Pro on 15/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

import Cocoa

class OverlayTextField: NSTextField {
    var command: Action?
    weak var overlayTextFieldDelegate: OverlayTextFieldDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    // default behaviour causes all text to be selected, so when the user types all text is erased
    // this fixes the behaviour
    // https://stackoverflow.com/a/32380549/10390454
    override func becomeFirstResponder() -> Bool {
        let responderStatus = super.becomeFirstResponder();
        
        let selectionRange = self.currentEditor()!.selectedRange
        self.currentEditor()?.selectedRange = NSMakeRange(selectionRange.length, 0);
        
        return responderStatus;
    }
    
    override func cancelOperation(_ sender: Any?) {
        self.overlayTextFieldDelegate?.onEscape()
    }
}

protocol OverlayTextFieldDelegate: AnyObject {
    func onEscape() -> Void
}
