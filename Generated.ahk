;Generated with ToggleScriptGenerator by u/PixelPerfect41
;https://github.com/Brawldude2/ToggleScriptGenerator-AHKv2
#Requires AutoHotkey v2.0
#SingleInstance Force

TIMER_DURATION_MS := 100
RUNNING := false


RunPeriodicallyWhenToggled(){
	Send('e')
	MsgBox("Hey")
}

EnableToggle(){
	global RUNNING
	if(RUNNING){
		return
	}
	SetTimer(RunPeriodicallyWhenToggled,TIMER_DURATION_MS)
	RUNNING := true
}

DisableToggle(){
	global RUNNING
	if(!RUNNING){
		return
	}
	SetTimer(RunPeriodicallyWhenToggled,0)
	RUNNING := false
}
