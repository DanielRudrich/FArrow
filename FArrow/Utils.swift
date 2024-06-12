//
//  Utils.swift
//  FArrow
//
//  Created by Daniel Rudrich on 02.06.24.
//

import SwiftUI

enum KeyCodes: Int64 {
    case F = 3
    case O = 31
    case U = 32
    case I = 34
    case L = 37
    case J = 38
    case K = 40
    case LEFT = 123
    case RIGHT = 124
    case DOWN = 125
    case UP = 126
    case PAGEUP = 116
    case PAGEDOWN = 121
}

func remapKeys(in event: CGEvent) {
    let keyCode = event.getIntegerValueField(CGEventField.keyboardEventKeycode)

    switch keyCode {
    case KeyCodes.J.rawValue:
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.LEFT.rawValue)
    case KeyCodes.L.rawValue:
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.RIGHT.rawValue)
    case KeyCodes.K.rawValue:
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.DOWN.rawValue)
    case KeyCodes.I.rawValue:
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.UP.rawValue)
    case KeyCodes.U.rawValue:
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.PAGEUP.rawValue)
    case KeyCodes.O.rawValue:
        event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: KeyCodes.PAGEDOWN.rawValue)
    default:
        break
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
