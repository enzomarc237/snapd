import Cocoa
import Carbon

/// Registers and listens for a global keyboard shortcut (⌘Space by default)
/// that can toggle the palette window from any application.
///
/// Uses the Carbon `RegisterEventHotKey` API which is the only public macOS API
/// that supports system-wide hotkeys without Accessibility permissions.
class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var callback: (() -> Void)?

    // ⌘Space: keyCode 49 (Space), modifier mask cmdKey.
    private let keyCode: UInt32 = 49
    private let modifiers: UInt32 = UInt32(cmdKey)
    // FourCC "snap" (0x736E6170) used as the event hot-key registration signature.
    private let hotkeySignature: OSType = 0x736E6170
    private var hotkeyID: EventHotKeyID { EventHotKeyID(signature: hotkeySignature, id: 1) }

    /// Registers the global hotkey and invokes [action] when it fires.
    func register(action: @escaping () -> Void) {
        self.callback = action

        // Install the Carbon event handler once.
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                       eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(),
                            { _, event, userData -> OSStatus in
                                guard let userData else { return noErr }
                                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                                manager.callback?()
                                return noErr
                            },
                            1,
                            &eventType,
                            Unmanaged.passUnretained(self).toOpaque(),
                            &eventHandlerRef)

        RegisterEventHotKey(keyCode, modifiers, hotkeyID,
                            GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    /// Unregisters the currently active hotkey.
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
        callback = nil
    }

    deinit {
        unregister()
    }
}
