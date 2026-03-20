; AUTO-GENERATED. DO NOT EDIT DIRECTLY.
; profile: default
#Requires AutoHotkey v2.0
#SingleInstance Force
SetCapsLockState "AlwaysOff"

; =========================================
; CapsLock -> LCtrl (manual, suppresses key repeats to prevent stuck Ctrl)
; =========================================
global g_capsCtrlDown := false

; --- 繝励Ο繧ｻ繧ｹ邨ゆｺ・凾縺ｫ繝｢繝・ぅ繝輔ぃ繧､繧｢繧ｭ繝ｼ繧貞ｼｷ蛻ｶ隗｣謾ｾ ---
OnExit(CleanupModifiers)

CleanupModifiers(ExitReason, ExitCode) {
    global g_capsCtrlDown
    g_capsCtrlDown := false
    ; Send 縺ｧ縺ｯ縺ｪ縺・DllCall 繧剃ｽｿ逕ｨ・・HK 繝｡繝・そ繝ｼ繧ｸ繝ｫ繝ｼ繝怜●豁｢蠕後ｂ蜍穂ｽ懶ｼ・
    ; VK: LCtrl=0xA2, RCtrl=0xA3, LShift=0xA0, RShift=0xA1, LAlt=0xA4, RAlt=0xA5
    ; KEYEVENTF_KEYUP = 2
    DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 2, "uptr", 0)
    DllCall("keybd_event", "uchar", 0xA3, "uchar", 0, "uint", 2, "uptr", 0)
    DllCall("keybd_event", "uchar", 0xA0, "uchar", 0, "uint", 2, "uptr", 0)
    DllCall("keybd_event", "uchar", 0xA1, "uchar", 0, "uint", 2, "uptr", 0)
    DllCall("keybd_event", "uchar", 0xA4, "uchar", 0, "uint", 2, "uptr", 0)
    DllCall("keybd_event", "uchar", 0xA5, "uchar", 0, "uint", 2, "uptr", 0)
    DllCall("keybd_event", "uchar", 0x5B, "uchar", 0, "uint", 2, "uptr", 0)  ; LWin
    DllCall("keybd_event", "uchar", 0x5C, "uchar", 0, "uint", 2, "uptr", 0)  ; RWin
}

; --- 迥ｶ諷区紛蜷域ｧ繧ｦ繧ｩ繝・メ繝峨ャ繧ｰ・・00ms 縺斐→縺ｫ desync 繧呈､懷・繝ｻ菫ｮ豁｣・・--
SetTimer(ValidateCapsCtrlState, 500)

ValidateCapsCtrlState() {
    global g_capsCtrlDown
    physCapsDown  := GetKeyState("CapsLock", "P")
    physCtrlDown  := GetKeyState("LCtrl",    "P")
    logicCtrlDown := GetKeyState("LCtrl",    "L")

    if g_capsCtrlDown and !physCapsDown {
        ; AHK 縺ｯ Ctrl 謚ｼ荳九→諤昴▲縺ｦ縺・ｋ縺・CapsLock 縺ｯ髮｢繧後※縺・ｋ 竊・desync
        g_capsCtrlDown := false
        DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 2, "uptr", 0)
    } else if !g_capsCtrlDown and physCapsDown and !logicCtrlDown {
        ; CapsLock 縺ｯ謚ｼ荳倶ｸｭ縺縺・Ctrl 縺檎匱陦後＆繧後※縺・↑縺・竊・蜀肴ｳｨ蜈･
        g_capsCtrlDown := true
        DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 0, "uptr", 0)
    } else if !g_capsCtrlDown and !physCapsDown and !physCtrlDown and logicCtrlDown {
        ; AHK は正常と思っているが LCtrl が論理的にスタックしているケース
        DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 2, "uptr", 0)
    }
}

*CapsLock::{
    global g_capsCtrlDown
    if g_capsCtrlDown  ; suppress key-repeat re-fire
        return
    g_capsCtrlDown := true
    DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 0, "uptr", 0)
}

*CapsLock up::{
    global g_capsCtrlDown
    if g_capsCtrlDown {
        DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 2, "uptr", 0)
        g_capsCtrlDown := false
    }
}

; Quick emergency: suspend all AHK remaps.
^!Pause::Suspend -1

; Emergency: release all stuck modifier keys (keep AHK running).
^!Escape::{
    global g_capsCtrlDown
    g_capsCtrlDown := false
    Send "{LCtrl up}{RCtrl up}{LShift up}{RShift up}{LAlt up}{RAlt up}"
    Send "{LWin up}{RWin up}"
}

; IME toggle (闍ｱ縺九↑) - CapsLock+Space (謗剃ｻ・ CapsLock 迚ｩ逅・款荳区凾縺ｮ縺ｿ)
#HotIf GetKeyState("CapsLock", "P")
*Space::{
    global g_capsCtrlDown
    if g_capsCtrlDown {
        DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 2, "uptr", 0)
        g_capsCtrlDown := false
    }
    hwnd := WinActive("A")
    ctx := DllCall("imm32\ImmGetContext", "ptr", hwnd, "ptr")
    state := ctx ? DllCall("imm32\ImmGetOpenStatus", "ptr", ctx, "int") : 0
    if ctx
        DllCall("imm32\ImmReleaseContext", "ptr", hwnd, "ptr", ctx)
    if state
        Send "{vkF4}"  ; IME off
    else
        Send "{vkF3}"  ; IME on (hiragana)
}
#HotIf

; IME toggle (闍ｱ縺九↑) - 螳・Ctrl+Space (謗剃ｻ・ CapsLock 迚ｩ逅・款荳九↑縺玲凾縺ｮ縺ｿ)
#HotIf !GetKeyState("CapsLock", "P")
^Space::{
    global g_capsCtrlDown
    if g_capsCtrlDown {
        DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 2, "uptr", 0)
        g_capsCtrlDown := false
    }
    hwnd := WinActive("A")
    ctx := DllCall("imm32\ImmGetContext", "ptr", hwnd, "ptr")
    state := ctx ? DllCall("imm32\ImmGetOpenStatus", "ptr", ctx, "int") : 0
    if ctx
        DllCall("imm32\ImmReleaseContext", "ptr", hwnd, "ptr", ctx)
    if state
        Send "{vkF4}"  ; IME off
    else
        Send "{vkF3}"  ; IME on (hiragana)
}
#HotIf

; Vim-style window navigation via komorebic (no-op if komorebic is unavailable).
!h::RunWait 'komorebic focus left', , 'Hide'
!j::RunWait 'komorebic focus down', , 'Hide'
!k::RunWait 'komorebic focus up', , 'Hide'
!l::RunWait 'komorebic focus right', , 'Hide'

; Move focused window.
!+h::RunWait 'komorebic move left', , 'Hide'
!+j::RunWait 'komorebic move down', , 'Hide'
!+k::RunWait 'komorebic move up', , 'Hide'
!+l::RunWait 'komorebic move right', , 'Hide'

; Resize focused window.
!a::RunWait 'komorebic resize-axis horizontal decrease', , 'Hide'
!d::RunWait 'komorebic resize-axis horizontal increase', , 'Hide'
!w::RunWait 'komorebic resize-axis vertical decrease', , 'Hide'
!s::RunWait 'komorebic resize-axis vertical increase', , 'Hide'

; Win->Ctrl remap disabled in this profile.

