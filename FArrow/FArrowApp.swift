//
//  FArrowApp.swift
//  FArrow
//
//  Created by Daniel Rudrich on 30.05.24.
//

import SwiftUI

var _eventTap: CFMachPort?
var fDown = false
var fDownUptimeTimestamp = UInt64(0)
let downInterval = 200_000_000 // ns

let eventTapCallback: CGEventTapCallBack = { proxy, type, event, _ in
    switch type {
    case .tapDisabledByTimeout:
        if let tap = _eventTap {
            CGEvent.tapEnable(tap: tap, enable: true) // Re-enable
        }

    case .keyUp:
        let keyCode = event.getIntegerValueField(CGEventField.keyboardEventKeycode)

        if keyCode == 3 {
            let fWasDown = fDown
            fDown = false

            if fWasDown, DispatchTime.now().uptimeNanoseconds - fDownUptimeTimestamp < downInterval {
                let e = CGEvent(
                    keyboardEventSource: nil,
                    virtualKey: 3,
                    keyDown: true
                )
                e?.tapPostEvent(proxy)
            }
        }

    case .keyDown:
        let keyCode = event.getIntegerValueField(CGEventField.keyboardEventKeycode)

        if keyCode == 3 {
            if fDown == false {
                fDown = true
                fDownUptimeTimestamp = DispatchTime.now().uptimeNanoseconds
            }
            return nil
        } else if fDown == true {
            if DispatchTime.now().uptimeNanoseconds - fDownUptimeTimestamp >= downInterval {
                if keyCode == 38 { // j -> left
                    event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: 123)
                } else if keyCode == 37 { // l -> right
                    event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: 124)
                } else if keyCode == 40 { // k -> down
                    event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: 125)
                } else if keyCode == 34 { // i -> up
                    event.setIntegerValueField(CGEventField.keyboardEventKeycode, value: 126)
                }
            } else {
                // cancel fDown
                fDown = false
                let e = CGEvent(
                    keyboardEventSource: nil,
                    virtualKey: 3,
                    keyDown: true
                )
                e?.tapPostEvent(proxy)
            }
        }

    default:
        break
    }
    return Unmanaged.passRetained(event)
}

final class AccessibilityPermissions: ObservableObject {
    @Published var granted = AXIsProcessTrusted()

    func pollAndRun(lambda: @escaping () -> Void) {
        let isGranted = AXIsProcessTrusted()
        granted = isGranted

        if !isGranted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.pollAndRun(lambda: lambda)
            }
        } else {
            lambda()
        }
    }

    static func acquire() {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true] as CFDictionary)
    }
}

@main
struct FArrowApp: App {
    @ObservedObject var permissions = AccessibilityPermissions()

    init() {
        if !permissions.granted {
            AccessibilityPermissions.acquire()
        }
        permissions.pollAndRun {
            let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

            guard let eventTap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(eventMask),
                callback: eventTapCallback,
                userInfo: nil
            ) else {
                fatalError("Failed to create event tap")
            }

            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    var body: some Scene {
        MenuBar(permissionsGranted: $permissions.granted)
    }
}

class MyTimer: ObservableObject {
    @Published var active: Bool = false
    var timer: Timer?

    init() {
        startTimer()
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in

            self.active = fDown && DispatchTime.now().uptimeNanoseconds - fDownUptimeTimestamp >= downInterval
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct MenuBar: Scene {
    @StateObject var myTimer = MyTimer()
    @Binding var permissionsGranted: Bool

    var body: some Scene {
        MenuBarExtra("FArrow", image: !permissionsGranted ? "FArrowNoPermissions" : myTimer.active ? "FArrowActive" : "FArrow") {
            AppMenu(permissionsGranted: $permissionsGranted)
        }
    }
}

struct AppMenu: View {
    @Binding var permissionsGranted: Bool

    func quit() { NSApplication.shared.terminate(nil) }

    var body: some View {
        if !permissionsGranted {
            Text("No Accessibility permissions granted.")
            Text("Please go to System Settings -> Privacy & Security -> Accessibility.")
            Divider()
        }

        Button(action: quit, label: { Text("Quit") })
    }
}
