//
//  FArrowApp.swift
//  FArrow
//
//  Created by Daniel Rudrich on 30.05.24.
//

import SwiftUI

var _eventTap: CFMachPort?
var fDown = false
var fDownTimestamp = CGEventTimestamp(0)
let downInterval = 8_000_000

@main
struct FArrowApp: App {
    let eventTapCallback: CGEventTapCallBack

    init() {
        eventTapCallback = { proxy, type, event, _ in
            switch type {
            case .tapDisabledByTimeout:
                if let tap = _eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true) // Re-enable
                }

            case .keyUp:
                let keyCode = event.getIntegerValueField(CGEventField.keyboardEventKeycode)

                if keyCode == 3 {
                    print("released f key")

                    let fWasDown = fDown

                    fDown = false

                    if fWasDown && event.timestamp - fDownTimestamp < downInterval {
                        print("f")
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
                        print("pressed f key")
                        fDown = true
                        fDownTimestamp = event.timestamp
                    }
                    return nil
                } else if fDown == true {
                    if event.timestamp - fDownTimestamp >= downInterval {
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

    var body: some Scene {
        ContentView()
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
            if fDown && DispatchTime.now().uptimeNanoseconds - fDownTimestamp >= downInterval {
                self.active = true
            } else {
                self.active = false
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct ContentView: Scene {
    @StateObject var myTimer = MyTimer()

    var body: some Scene {
        MenuBarExtra("FArrow", image: myTimer.active ? "FArrowActiveLogo" : "FArrowLogo") {
            AppMenu()
        }
    }
}

struct AppMenu: View {
    func quit() { NSApplication.shared.terminate(nil) }

    var body: some View {
        Button(action: quit, label: { Text("Quit") })
    }
}
