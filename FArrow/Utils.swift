//
//  Utils.swift
//  FArrow
//
//  Created by Daniel Rudrich on 02.06.24.
//

import SwiftUI

enum KeyCodes: Int64 {
    case F = 3
    case I = 34
    case L = 37
    case J = 38
    case K = 40
    case LEFT = 123
    case RIGHT = 124
    case DOWN = 125
    case UP = 126
}

func remapKeys(in event: CGEvent) {
    let keyCode = event.getIntegerValueField(CGEventField.keyboardEventKeycode)

    if keyCode == KeyCodes.J.rawValue {
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.LEFT.rawValue)
    } else if keyCode == KeyCodes.L.rawValue {
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.RIGHT.rawValue)
    } else if keyCode == KeyCodes.K.rawValue {
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.DOWN.rawValue)
    } else if keyCode == KeyCodes.I.rawValue {
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.UP.rawValue)
    }
}

func postVirtualFEvent(to proxy: CGEventTapProxy, keyDown: Bool) {
    let e = CGEvent(
        keyboardEventSource: nil,
        virtualKey: UInt16(KeyCodes.F.rawValue),
        keyDown: keyDown
    )
    e?.tapPostEvent(proxy)
}
