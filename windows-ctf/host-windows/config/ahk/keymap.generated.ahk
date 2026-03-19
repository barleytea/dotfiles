; AUTO-GENERATED. DO NOT EDIT DIRECTLY.
; profile: default
#Requires AutoHotkey v2.0
#SingleInstance Force
SetCapsLockState "AlwaysOff"

; Always keep CapsLock behavior as Ctrl for Mac-like ergonomics.
CapsLock::Ctrl

; Quick emergency: suspend all AHK remaps.
^!Pause::Suspend -1

; IME toggle (闍ｱ縺九↑蛻・ｊ譖ｿ縺・ - real Ctrl+Space.
^Space::{
    Send "{Ctrl Up}"
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

; IME toggle (闍ｱ縺九↑蛻・ｊ譖ｿ縺・ - only when CapsLock is physically held.
#HotIf GetKeyState("CapsLock", "P")
*Space::{
    Send "{Ctrl Up}"
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

