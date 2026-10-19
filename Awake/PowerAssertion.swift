import Foundation
import IOKit.pwr_mgt

/// A held IOKit power assertion that stops the display (and therefore the
/// system) from idle sleeping, the same assertion `caffeinate -d` creates.
/// The assertion is released on `release()`, on deinit, and by the kernel
/// when the process exits, so nothing lingers after quitting.
final class PowerAssertion {
    private var id: IOPMAssertionID = IOPMAssertionID(0)
    private var isHeld = false

    init?(reason: String) {
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &id
        )
        guard result == kIOReturnSuccess else { return nil }
        isHeld = true
    }

    func release() {
        guard isHeld else { return }
        IOPMAssertionRelease(id)
        isHeld = false
    }

    deinit {
        release()
    }
}
