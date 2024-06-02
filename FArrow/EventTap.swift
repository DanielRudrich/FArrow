//
//  EventTap.swift
//  FArrow
//
//  Created by Daniel Rudrich on 02.06.24.
//

import SwiftUI

// globals :-/
var _eventTap: CFMachPort?
var fDown = false
var fDownUptimeTimestamp = UInt64(0)
let downInterval = 150_000_000 // ns

let eventTapCallback: CGEventTapCallBack = { proxy, type, event, _ in
    let keyCode = event.getIntegerValueField(CGEventField.keyboardEventKeycode)

    switch type {
    case .tapDisabledByTimeout:
        if let tap = _eventTap {
            CGEvent.tapEnable(tap: tap, enable: true) // Re-enable
        }

    case .keyUp:
        if keyCode == KeyCodes.F.rawValue {
            let fWasDown = fDown
            fDown = false

            if fWasDown, DispatchTime.now().uptimeNanoseconds - fDownUptimeTimestamp < downInterval {
                postVirtualFEvent(to: proxy, keyDown: true)
            }
        } else {
            if fDown {
                if DispatchTime.now().uptimeNanoseconds - fDownUptimeTimestamp >= downInterval {
                    remapKeys(in: event)
                }
            }
        }

    case .keyDown:
        if keyCode == KeyCodes.F.rawValue {
            if fDown == false {
                fDown = true
                fDownUptimeTimestamp = DispatchTime.now().uptimeNanoseconds
            }
            return nil
        } else if fDown == true {
            if DispatchTime.now().uptimeNanoseconds - fDownUptimeTimestamp >= downInterval {
                remapKeys(in: event)
            } else {
                // cancel fDown
                fDown = false
                postVirtualFEvent(to: proxy, keyDown: true)
            }
        }

    default:
        break
    }
    return Unmanaged.passRetained(event)
}
