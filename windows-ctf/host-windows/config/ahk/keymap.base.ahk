#Requires AutoHotkey v2.0
#SingleInstance Force
SetCapsLockState "AlwaysOff"

; Always keep CapsLock behavior as Ctrl for Mac-like ergonomics.
CapsLock::Ctrl

; Quick emergency: suspend all AHK remaps.
^!Pause::Suspend -1

; App launcher shortcut similar to Raycast habit.
^Space::Run "flow-launcher://"

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
