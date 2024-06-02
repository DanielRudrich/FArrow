//
//  AccessibilityPermissions.swift
//  FArrow
//
//  Created by Daniel Rudrich on 02.06.24.
//

import SwiftUI

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
