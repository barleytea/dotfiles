#Requires AutoHotkey v2.0

*LWin::{
    SendInput("{Blind}{LCtrl down}")
}    
*LWin up::{
    SendInput("{Blind}{LCtrl up}")
    if (A_PriorKey == "LWin"){
        SendInput("{vk1D}")
    }
}

*RWin::{
    SendInput("{Blind}{RCtrl down}")
}    
*RWin up::{
    SendInput("{Blind}{RCtrl up}")
    if (A_PriorKey == "RWin"){
        SendInput("{vk1C}")
    }
}

; <r-alt>b    # move cursor one word backward
>!b:: Send "^{Left}"
