class ToggleBind{
    __New(_Hotkey,_Type,_Params*){
        this.Hotkey := _Hotkey
        this.Type := _Type
        this.Params := Array(_Params*)
    }

    ToString(){
        if(SubStr(this.Type,1,12)=="HoldToToggle"){
            if(InStr(this.Type,"2 binds")){
                str := String(ToggleBind(this.Hotkey,"EnableToggle"))
                str .= String(ToggleBind(this.Hotkey " up","DisableToggle"))
                return str
            }else{
                this.Params := Array("`"" this.Hotkey "`"")
            }
        }

        str := "$" this.Hotkey "::" this.Type "("
        for i,param in this.Params{
            str .= param ", "
        }
        if(this.Params.Length){
            str := SubStr(str,1,StrLen(str)-2)
        }
        str .= ")`n"
        return str
    }
}

class Flag{
    __New(val,editable:=false){
        this.Value := val
        this.Editable := editable
    }
}

class Editor{
    Settings := Map()
    Settings.Default := ""
    ActiveScript := Script(this)
    SnippetManager := SnippetManager()

    ValidateFlags(){
        for func,content in this.GetFunctions(){
            if(content){
                this.SetFlag(func,true)
            }
        }
        for i,bind in this.GetBinds(){
            if(this.ActiveScript.Flags.Has(bind.Type)){
                this.SetFlag(bind.Type,true)
            }
        }
    }

    GetReservedFlags(){
        mp := Map()
        for k,flag in this.ActiveScript.Flags{
            if(!flag.Editable){
                mp.Set(k,flag)
            }
        }
        return mp
    }

    GetEditableFlags(){
        mp := Map()
        for k,flag in this.ActiveScript.Flags{
            if(flag.Editable){
                mp.Set(k,flag)
            }
        }
        return mp
    }

    ;Returns the flag with the specified key
    GetFlag(key){
        return this.ActiveScript.Flags[key]
    }
    SetFlag(key,val){
        this.ActiveScript.Flags[key].Value := val
    }

    GetBinds(){
        return this.ActiveScript.Binds
    }

    GetFunctions(){
        return this.ActiveScript.CustomisableFunctions
    }

    GetGlobalVariables(){
        return this.ActiveScript.Settings
    }

    GenerateScript(){
        this.ValidateFlags()
        return String(this.ActiveScript)
    }
}

class Script{
    __New(Editor){
        this.Editor := Editor
    }

    Settings := Map(
        "TimerDurationMS",100,
        "SendMode","Event"
    )
    Settings.Default := ""

    Flags := Map(
        "GUI_Mode",Flag(false,true),
        "AlwaysOnTop",Flag(false,true),
        "RunRightOff",Flag(true,true),

        "RunOnceWhenToggled",Flag(false),
        "RunPeriodicallyWhenToggled",Flag(true),
        "RunWhenToggleIsDisabled",Flag(false),
        "SwitchToggle",Flag(false),
        "HoldToToggle",Flag(false),
        "EnableToggle",Flag(true),
        "DisableToggle",Flag(true),
        "onClick",Flag(false)
    )
    Flags.Default := Flag(false)

    Binds := Array()

    CustomisableFunctions := Map(
        "RunOnceWhenToggled","",
        "RunPeriodicallyWhenToggled","Send('e')",
        "RunWhenToggleIsDisabled",""
    )
    CustomisableFunctions.Default := ""

    GetGUIOptions(){
        str := "`""
        if(this.Flags["AlwaysOnTop"].Value){
            str .= "+AlwaysOnTop "
        }
        str .= "`""
        return str
    }

    ToString(){
        this.Editor.SnippetManager.Flags := this.Flags

        str := ""
        str .=
        (
            ';Generated with ToggleScriptGenerator by u/PixelPerfect41
            ;https://github.com/Brawldude2/ToggleScriptGenerator-AHKv2
            #Requires AutoHotkey v2.0
            #SingleInstance Force
            
            TIMER_DURATION_MS := ' this.Settings["TimerDurationMS"] '
            RUNNING := false

            '
        )
        if(this.Settings["SendMode"]!="Input")
            str .= "SendMode(`"" this.Settings["SendMode"] "`")`n"
        for i,bind in this.Binds{
            str .= String(bind)
        }
        if(this.Flags["GUI_Mode"].Value){
            str .=
            (
                '
                UI := CreateGUI()
                UI.Show("w200 h124")
                '
            )
        }

        for func,code in this.CustomisableFunctions{
            if(this.Flags[func].Value){
                str .= "`n" func "(){`n`t" StrReplace(code,"`r`n","`r`n`t") "`n}`n"
            }
        }

        if(this.Flags["EnableToggle"].Value){
            str .= String(this.Editor.SnippetManager.EnableToggle)
        }
        if(this.Flags["DisableToggle"].Value){
            str .= String(this.Editor.SnippetManager.DisableToggle)
        }
        if(this.Flags["SwitchToggle"].Value){
            str .= String(this.Editor.SnippetManager.SwitchToggle)
        }
        if(this.Flags["HoldToToggle"].Value){
            str .= String(this.Editor.SnippetManager.HoldToToggle)
        }

        if(this.Flags["GUI_Mode"].Value){
            ;TODO: Add gui options
            str .= String(this.Editor.SnippetManager.onClick)
            str .= String(this.Editor.SnippetManager.CreateGUI)
        }

        str := StrReplace(str,"__GUI_OPTIONS__",this.GetGUIOptions())

        return str
    }
}

Class CodeSnippet{
    Flags := Map()
    Flags.Default := Flag(false)
    CodeBlocks := Map()
    CodeBlocks.Default := ""

    FlagOrder := [
        "__Init__",
        "EnableToggle",
        "DisableToggle",
        "RunOnceWhenToggled",
        "RunRightOff",
        "RunPeriodicallyWhenToggled",
        "RunWhenToggleIsDisabled",
        "__Main__",
        "GUI_Mode",
        "__End__"
    ]

    __New(params*){
        this.CodeBlocks.Set(params*)
    }

    ToString(){
        str := ""
        for i,flag in this.FlagOrder{
            if(this.Flags[flag].Value or (SubStr(flag,1,2)=="__" and SubStr(flag,-2)=="__")){
                str .= this.CodeBlocks[flag]
            } 
        }
        return StrReplace(str,"    ","`t")
    }
}

class SnippetManager{
    Flags := Map()
    Flags.Default := Flag(false)

    __Get(Key, *) {
        if(this.CodeSnippets.HasProp(Key)){
            this.CodeSnippets.%Key%.Flags := this.Flags
            return this.CodeSnippets.%Key%
        }
        return ""
    }

    CodeSnippets := {
        CreateGUI:CodeSnippet(
            "__Main__",
            (
                'CreateGUI(){
                    UI := Gui(__GUI_OPTIONS__)
                    UI.Title := "YOUR TITLE"
                    UI.OnEvent("Close", (*) => ExitApp())
                    UI.SetFont("s18")
                    
                    StartStop := UI.Add("Button","w200 h124 x0 y0 vCtrl_StartStop","START")
                    StartStop.OnEvent("Click",onClick)
                    
                    return UI
                }'
            )
        ),
    
        onClick:CodeSnippet(
            "__Init__",
                "onClick(Button,*){",
            "__Main__",
            (
                '
                    if(!RUNNING){
                        EnableToggle()
                    }else{
                        DisableToggle()
                    }
                '
            ),
            "__End__",
                '}'
        ),
    
        EnableToggle:CodeSnippet(
            "__Init__",
            (
                '
                EnableToggle(){
                    global RUNNING
                    if(RUNNING){
                        return
                    }'
            ),
            "RunOnceWhenToggled",
            (
                '
                    RunOnceWhenToggled()'
            ),
            "RunRightOff",
            (
                '
                    SetTimer(RunPeriodicallyWhenToggled,-1)'
            ),
            "RunPeriodicallyWhenToggled",
            (
                '
                    SetTimer(RunPeriodicallyWhenToggled,TIMER_DURATION_MS)'
            ),
            "__Main__",
            (
                '
                    RUNNING := true
                '
            ),
            "GUI_Mode",
            (
                '
                    global UI
                    UI["Ctrl_StartStop"].Text := "STOP"
                '
            ),
            "__End__",
                '}`n'
        ),
    
        DisableToggle:CodeSnippet(
            "__Init__",
            (
                '
                DisableToggle(){
                    global RUNNING
                    if(!RUNNING){
                        return
                    }'
            ),
            "RunPeriodicallyWhenToggled",
            (
                '
                    SetTimer(RunPeriodicallyWhenToggled,0)'
            ),
            "RunWhenToggleIsDisabled",
            (
                '
                    RunWhenToggleIsDisabled()'
            ),
            "__Main__",
            (
                '
                    RUNNING := false
                '
            ),
            "GUI_Mode",
            (
                '
                    global UI
                    UI["Ctrl_StartStop"].Text := "START"
                '
            ),
            "__End__",
            (
                '}
                '
            )
        ),
    
        HoldToToggle:CodeSnippet(
            "__Main__",
            (
                '
                HoldToToggle(key){
                    EnableToggle()
                    KeyWait(key)
                    DisableToggle()
                }
                '
            )
        ),
    
        SwitchToggle:CodeSnippet(
            "__Main__",
            (
                '
                SwitchToggle(){
                    if(RUNNING){
                        DisableToggle()
                    }else{
                        EnableToggle()
                    }
                }
                '
            )
        ) 
    }
}

/*
(Code Block Order)
__Init__
EnableToggle
DisableToggle
RunOnceWhenToggled
RunRightOff
RunPeriodicallyWhenToggled
RunWhenToggleIsDisabled
__Main__
GUI_Mode
__End__
*/