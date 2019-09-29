//
//  KeyPosition.swift
//  Vimac
//
//  Created by Huawei Matebook X Pro on 26/9/19.
//  Copyright © 2019 Dexter Leng. All rights reserved.
//

enum KeyPosition { case
    keyDown,
    keyUp
}

struct KeyAction {
    let keyPosition: KeyPosition
    let character: Character
}
