;Generated with ToggleScriptGenerator by u/PixelPerfect41
;https://github.com/Brawldude2/ToggleScriptGenerator-AHKv2
#Requires AutoHotkey v2.0
#SingleInstance Force

TIMER_DURATION_MS := 0
RUNNING := false

SendMode("Event")
$w::HoldToToggle("w")

RunOnceWhenToggled(){
	Send('{Shift down}')
}

RunWhenToggleIsDisabled(){
	Send('{Shift up}')
}

EnableToggle(){
	global RUNNING
	if(RUNNING){
		return
	}
	RunOnceWhenToggled()
	RUNNING := true
}

DisableToggle(){
	global RUNNING
	if(!RUNNING){
		return
	}
	RunWhenToggleIsDisabled()
	RUNNING := false
}

HoldToToggle(key){
	EnableToggle()
	KeyWait(key)
	DisableToggle()
}
