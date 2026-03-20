#Requires AutoHotkey v2.0
#SingleInstance Force
SetCapsLockState "AlwaysOff"

; =========================================
; CapsLock -> LCtrl (manual, suppresses key repeats to prevent stuck Ctrl)
; =========================================
global g_capsCtrlDown := false

; --- プロセス終了時にモディファイアキーを強制解放 ---
OnExit(CleanupModifiers)

CleanupModifiers(ExitReason, ExitCode) {
    global g_capsCtrlDown
    g_capsCtrlDown := false
    ; Send ではなく DllCall を使用（AHK メッセージループ停止後も動作）
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

; --- 状態整合性ウォッチドッグ（500ms ごとに desync を検出・修正）---
SetTimer(ValidateCapsCtrlState, 500)

ValidateCapsCtrlState() {
    global g_capsCtrlDown
    physCapsDown  := GetKeyState("CapsLock", "P")
    logicCtrlDown := GetKeyState("LCtrl",    "L")

    if g_capsCtrlDown and !physCapsDown {
        ; AHK は Ctrl 押下と思っているが CapsLock は離れている → desync
        g_capsCtrlDown := false
        DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 2, "uptr", 0)
    } else if !g_capsCtrlDown and physCapsDown and !logicCtrlDown {
        ; CapsLock は押下中だが Ctrl が発行されていない → 再注入
        g_capsCtrlDown := true
        DllCall("keybd_event", "uchar", 0xA2, "uchar", 0, "uint", 0, "uptr", 0)
    }
}

*CapsLock::{
    global g_capsCtrlDown
    if g_capsCtrlDown  ; suppress key-repeat re-fire
        return
    g_capsCtrlDown := true
    Send "{LCtrl Down}"
}

*CapsLock up::{
    global g_capsCtrlDown
    if g_capsCtrlDown {
        g_capsCtrlDown := false
        Send "{LCtrl Up}"
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

; IME toggle (英かな) - CapsLock+Space (排他: CapsLock 物理押下時のみ)
#HotIf GetKeyState("CapsLock", "P")
*Space::{
    global g_capsCtrlDown
    if g_capsCtrlDown {
        g_capsCtrlDown := false
        Send "{LCtrl Up}"
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

; IME toggle (英かな) - 実 Ctrl+Space (排他: CapsLock 物理押下なし時のみ)
#HotIf !GetKeyState("CapsLock", "P")
^Space::{
    global g_capsCtrlDown
    if g_capsCtrlDown {
        g_capsCtrlDown := false
        Send "{LCtrl Up}"
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
