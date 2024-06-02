//
//  FArrowApp.swift
//  FArrow
//
//  Created by Daniel Rudrich on 30.05.24.
//

import SwiftUI

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
