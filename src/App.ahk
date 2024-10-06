#Include ToggleScriptGenerator.ahk

GetKeysFromMap(mp){
    arr := Array()
    for key,val in mp{
        arr.Push(key)
    }
    return arr
}

GetMapIndex(mp,search,opt:="key"){
    for k,v in mp{
        if(opt:="key"){
            if(k==search){
                return A_Index
            }
        }else{
            if(v==search){
                return A_Index
            }
        }
    }
    return 0
}

ArrayToMap(arr,arr_opt:="key"){
    mp := Map()
    for i,v in arr{
        if(arr_opt=="key"){
            mp.Set(v,i)
        }else{
            mp.Set(i,v)
        }
    }
}

class PopUp extends Gui{
    Input := {}
    Output := {}
    Init(){
        this.OnEvent("Escape",(*)=>this.Close())
        this.TimerFunc := ObjBindMethod(this,"CheckActive")
        return this
    }
    Update(){
    }
    Run(){
        this.Update()
        this.Show("w200 h100")
    }
    Close(){
        SetTimer(this.TimerFunc,0)
        this.Hide()
    }
    CheckActive(){
        if(!WinActive(this.getHandle())){
            SetTimer(this.TimerFunc,0)
            this.Close()
        }
    }
    setTimer(Method,Period){
        function := ObjBindMethod(this,Method)
        SetTimer(function,Period)
        return function
    }

    getHandle(){
        return "ahk_id " this.Hwnd
    }
}

class App extends Editor{
    PopUps := {}

    FunctionDescriptions := Map(
        "RunOnceWhenToggled","Runs right before toggle is enabled.",
        "RunPeriodicallyWhenToggled","This function will continously loop until toggle is disabled with a set delay.`r`nTip: If you are a beginner this is the place you will put your toggle code in.",
        "RunWhenToggleIsDisabled","Runs right after toggle is disabled."
    )

    __New(){   
        this.PopUps.FeatureEditor := App.PopUpContainer.FeatureEditor().Init(this)
        this.PopUps.HotkeyEditor := App.PopUpContainer.HotkeyEditor().Init(this)
        this.PopUps.HotkeyEdit := App.PopUpContainer.HotkeyEdit().Init(this)
        this.PopUps.GlobalVariableEditor := App.PopUpContainer.GlobalVariableEditor().Init(this)
        this.PopUps.VarEdit := App.PopUpContainer.VarEdit().Init(this)
        this.GUI_Constructor()
    }

    GUI_Constructor(){
        this.UI := Gui()
        this.UI.Title := "Toggle Script Generator v1.0"
        this.UI.Name := "Toggle Script Generator"
        this.UI.BackColor := 0x1f1f1f
        this.UI.SetFont("s16 c0xffffff","Consolas"),

        this.UI.Add("Progress","x10 y10 w180 h50 Background464646 Disabled")
        B := this.UI.Add("Text","x10 y10 w180 h50 Center BackgroundTrans","Optional Features")
        B.OnEvent("Click",(*)=>this.PopUps.FeatureEditor.Run())

        this.UI.Add("Progress","x200 ym-2 w180 h50 Background464646 Disabled")
        B := this.UI.Add("Text","x200 ym-2 w180 h50 Center 0x200 BackgroundTrans","Edit Hotkeys")
        B.OnEvent("Click",(*)=>this.PopUps.HotkeyEditor.Run())

        this.UI.SetFont("s16")
        this.UI.Add("Text","x10 w50","Editing:")
        this.UI.SetFont("s10")
        this.UI.Add("DropDownList","x+0 yp+2 w220 Choose2 vFunctionSelector",GetKeysFromMap(this.ActiveScript.CustomisableFunctions)).OnEvent("Change",(*)=>this.Update())
        this.UI.SetFont("s16")
        this.UI.Add("GroupBox","x10 y100 w380 h130","Description:")
        this.UI.SetFont("s12")
        this.UI.Add("Edit","x20 y130 w360 h90 ReadOnly +VScroll Background1f1f1f vDescription","Description.")

        this.UI.Add("Text","y+20 x10 vFunctionEntrance","RunOnceWhenToggled(){")
        this.UI.Add("Edit","y+5 xp+36 w330 r8 -HScroll -Border Background2e2e2e vFunctionEdit","Send('w')").OnEvent("LoseFocus",(*)=>this.SaveEdit())
        this.UI.Add("Text","y+5 x10","}")

        this.UI.SetFont("s16")
        this.UI.Add("Progress","x10 y+10 w380 h32 Background464646 Disabled")
        B := this.UI.Add("Text","x10 yp w380 h32 Center 0x200 BackgroundTrans","Edit Global Variables")
        B.OnEvent("Click",(*)=>this.PopUps.GlobalVariableEditor.Run())

        this.UI.SetFont("s12")
        this.UI.Add("Text","x10 y+15","Filename:")
        this.UI.Add("Edit","x+5 w295 r1 -VScroll vFilenameEdit Background000000","Generated.ahk").OnEvent("LoseFocus",(*)=>this.AddExtension())

        this.UI.Add("Text","x10 y+10 w30 h20 Background000000 Disabled")
        this.UI.Add("Text","x10 yp w30 h20 BackgroundTrans","...").OnEvent("Click",(*)=>this.SelectDir())
        this.UI.Add("Text","x+15","Dir:")
        this.UI.Add("Edit","x+10 r1 w290 -VScroll vDirectoryEdit ReadOnly Background000000",A_ScriptDir)

        this.UI.SetFont("s16")
        this.UI.Add("Progress","x10 y+10 w380 h32 Background464646 Disabled")
        B := this.UI.Add("Text","x10 yp w380 h32 Center 0x200 BackgroundTrans","Generate!")
        B.OnEvent("Click",(*)=>this.SaveScript())

        this.Update()
    }

    Update(){
        func_name := this.UI["FunctionSelector"].Text
        this.UI["Description"].Text := this.FunctionDescriptions[func_name]
        this.UI["FunctionEdit"].Text := this.GetFunctions()[func_name]
    }
    Run(){
        this.UI.Show("w400 h620")
    }
    SaveScript(){
        this.SaveEdit()
        fn := this.UI["FilenameEdit"].Text
        dir := this.UI["DirectoryEdit"].Text
        f := FileOpen(dir "\" fn,"w")
        f.Write(this.GenerateScript())
        f.Close()
        MsgBox("File Generated Succesfully!")
    }
    SaveEdit(){
        func_name := this.UI["FunctionSelector"].Text
        this.GetFunctions()[func_name] := this.UI["FunctionEdit"].Text
    }
    AddExtension(){
        str := this.UI["FilenameEdit"].Text
        if(!str){
            str := "Generated.ahk"
        }
        str := RegExReplace(str,'[<>:"\\\/|?*]',"_") ;Make it windows compatible file name
        if(SubStr(str,-4)!=".ahk"){
            str .= ".ahk"
        }
        this.UI["FilenameEdit"].Text := str
    }
    SelectDir(){
        Directory := DirSelect("::{20D04FE0-3AEA-1069-A2D8-08002B30309D}",,"Select a folder to save generated script.")
        this.UI["DirectoryEdit"].Text := Directory
    }

    class PopUpContainer{
        class FeatureEditor extends PopUp{
            Init(App){
                this.App := App
                this.Parent := App.PopUps
                this.TimerFunc := ObjBindMethod(this,"CheckActive")

                this.OnEvent("Escape",(*) => this.Close())
                this.Title := "Edit Features"
                this.SetFont("s10")
                LV := this.Add("ListView","x0 y0 r10 Checked -LV0x10 -Multi vEditableFlags",["Name","Value"])
                LV.OnEvent("ItemCheck",(p*) => this.onItemChecked(p*))
                this.Add("ListView","x0 y250 r10 -LV0x10 -Multi vReservedFlags",["Name","Value"])
                return this
            }

            Run(){
                this.Update()
                this.Show("h500 w300")
                WinWait(this.getHandle())
                WinActivate()
                SetTimer(this.TimerFunc,100)
            }

            onItemChecked(LV,Item,Checked){
                LV.Modify(Item,,,Checked)
                this.App.GetFlag(LV.GetText(Item,1)).Value := Checked
            }

            Update(){
                LV := this["EditableFlags"]
                LV2 := this["ReservedFlags"]

                LV.Delete()
                LV2.Delete()

                for k,flg in this.App.GetEditableFlags(){
                    checked := 0
                    if(flg.Value){
                        checked := "-"
                    }else{
                        checked := "+"
                    }
                    LV.Add(checked "Checked",k,flg.Value)
                }
                LV.ModifyCol()

                for k,flg in this.App.GetReservedFlags(){
                    LV2.Add(,k,flg.Value)
                }
                LV2.ModifyCol()
            }
        }

        class HotkeyEditor extends PopUp{
            Init(App){
                this.OnEvent("Escape",(*) => this.Close())
                this.App := App
                this.Parent := App.PopUps
                this.Title := "Edit Hotkeys"
                this.SetFont("s10")
                this.Add("ListView","x0 y0 w255 h260 -LV0x10 vBinds NoSort -Multi",["Hotkey","Function"]).OnEvent("ItemFocus",(p*)=>this.onItemFocus(p*))
                this.Add("Button","x260 y5 w85 h30 vEdit","Edit").OnEvent("Click",(*)=>this.EditHotkey())
                this.Add("Button","x260 y40 w85 h30 vAdd","Add").OnEvent("Click",(*)=>this.AddHotkey())
                this.Add("Button","x260 y265 w85 h30 vDelete","Delete").OnEvent("Click",(*)=>this.DeleteHotkey())
                this.Add("Hotkey","x5 y265 w245 h30 +ReadOnly vHotkeyView","")
                return this
            }
            Run(){
                this.Update()
                this.Show("h300 w350")
            }
            Update(){
                LV := this["Binds"]
                LV.Delete()
                for i,bind in this.App.GetBinds(){
                    LV.Add(,bind.Hotkey,bind.Type)
                }
                LV.ModifyCol(1,78)
                LV.ModifyCol(2,173)
            }
            EditHotkey(){
                LV := this["Binds"]
                row := LV.GetNext(,"F")
                if(row){
                    this.App.PopUps.HotkeyEdit.Input.BindIndex := row
                    this.App.PopUps.HotkeyEdit.Run()
                }
            }
            AddHotkey(){
                this.App.PopUps.HotkeyEdit.Input := {}
                this.App.PopUps.HotkeyEdit.Run()
            }
            DeleteHotkey(){
                row := this["Binds"].GetNext(,"F")
                if(row){
                    this.App.GetBinds().RemoveAt(row)
                    this.Update()
                }
            }
            onItemFocus(LV, Item){
                this["HotkeyView"].Value := this.App.GetBinds()[Item].Hotkey
            }
        }

        class HotkeyEdit extends PopUp{

            FunctionDescriptions := Map(
                "SwitchToggle","Switches toggle state. If toggle is on turns it off, if toggle is off turns it on.",
                "HoldToToggle","Allows you to run a toggle only while a key is held. `r`nLimitations: modifier keys can not be used.",
                "HoldToToggle(2 binds)", "A different version of HoldToToggle that uses 2 binds instead of KeyWait. One for key down one for key up.",
                "EnableToggle","Turns toggle on.",
                "DisableToggle", "Turns toggle off."
            )
            FunctionDescriptions.Default := "This function does nothing."
            FunctionNames := GetKeysFromMap(this.FunctionDescriptions)

            Init(App){
                this.App := App
                this.Parent := App.PopUps
                this.TimerFunc := ObjBindMethod(this,"CheckActive")

                this.OnEvent("Escape",(*) => this.Close())
                this.Title := "Edit Hotkeys"
                this.SetFont("s10")
                this.Add("GroupBox","x5 y5 w250 h110","Hotkey")
                this.Add("Text","x20 y30","Record")
                this.Add("Hotkey","x70 y27 w170 h23 vRecordHotkey","+s").OnEvent("Change",(*)=>this.RecordHotkey())

                this.Add("Text","x20 y60","Input")
                this.Add("Edit","x70 y57 w170 h23 vHotkeyInput","+s").OnEvent("Change",(*)=>this.InputHotkey())
                this.Add("Link","",'<a href="https://www.autohotkey.com/docs/v2/KeyList.htm">List of Hotkeys</a>')

                this.Add("GroupBox","x5 y120 w250 h150","Function")
                this.Add("Text","x15 y145","Function")
                this.Add("DropDownList","x70 y142 w170 Choose1 vFunctionSelector",this.FunctionNames).OnEvent("Change",(*)=>this.Update())
                this.Add("Text","x15 y170","Description")
                this.Add("Edit","x15 y190 w230 h70 +ReadOnly vDescription","This function does nothing.")

                this.Add("Button","x15 y275","Save").OnEvent("Click",(*)=>this.Save())
                this.Add("Button","x70 y275","Save and Quit").OnEvent("Click",(*)=>this.Save(quit:=1))

                return this
            }
            Run(){
                if(this.Input.HasProp("BindIndex")){
                    idx := this.Input.BindIndex
                    bind := this.App.ActiveScript.Binds[idx]
                    this["FunctionSelector"].Choose(GetMapIndex(this.FunctionDescriptions,bind.Type))
                    this["HotkeyInput"].Text := bind.Hotkey
                    this.InputHotkey()
                    this["HotkeyInput"].Focus()
                }
                this.Update()
                this.Show("h310 w350")
                WinWait(this.getHandle())
                WinActivate()
                SetTimer(this.TimerFunc,100)
            }

            UpdateDescription(){
                this["Description"].Text := this.FunctionDescriptions[this["FunctionSelector"].Text]
            }
            Save(quit:=0){
                if(this.Input.HasProp("BindIndex")){
                    idx := this.Input.BindIndex
                    bind := this.App.ActiveScript.Binds[idx]
                    bind.Hotkey := this["HotkeyInput"].Text
                    bind.Type := this["FunctionSelector"].Text
                }else{
                    bind := ToggleBind(this["HotkeyInput"].Text,this["FunctionSelector"].Text)
                    this.App.ActiveScript.Binds.Push(bind)
                }
                if(quit){
                    this.Close()
                }
            }
            Update(){
                this.UpdateDescription()
            }
            Close(){
                this.Hide()
                this.App.PopUps.HotkeyEditor.Run()
            }
            InputHotkey(){
                this["RecordHotkey"].Value := this["HotkeyInput"].Text
            }
            RecordHotkey(){
                this["HotkeyInput"].Text := this["RecordHotkey"].Value
            }
        }

        class GlobalVariableEditor extends PopUp{
            Init(App){
                this.OnEvent("Escape",(*) => this.Close())
                this.App := App
                this.Parent := App.PopUps
                this.Title := "Edit Global Variables"
                this.SetFont("s10")
                this.Add("ListView","x0 y0 w300 h300 -LV0x10 vVariables NoSort -Multi",["Variable","Value"]).OnEvent("DoubleClick",(p*)=>this.EditVar(p*))
                return this
            }
            Run(){
                this.Update()
                this.Show("h300 w300")
            }
            Update(){
                LV := this["Variables"]
                LV.Delete()
                for name,val in this.App.GetGlobalVariables(){
                    LV.Add(,name,val)
                }
                LV.ModifyCol(1,150)
                LV.ModifyCol(2,146)
            }
            EditVar(LV,row){
                row := LV.GetNext(,"F")
                if(row){
                    this.App.PopUps.VarEdit.Input.VarName := LV.GetText(row,1)
                    this.App.PopUps.VarEdit.Run()
                }
            }
        }

        class VarEdit extends PopUp{
            Init(App){
                this.TimerFunc := ObjBindMethod(this,"CheckActive")
                this.OnEvent("Escape",(*) => this.Close())
                this.App := App
                this.Parent := App.PopUps
                this.Title := ""
                this.Add("Edit","x5 y5 w190 vValueInput")
                this.SetFont("s16")
                this.Add("Button","x5 y+5 w190 h50","OK").OnEvent("Click",(*)=>this.AcceptValue())
                return this
            }
            Run(){
                SetTimer(this.TimerFunc,100)
                this.Update()
                this.Show("h90 w200")
            }
            AcceptValue(){
                VarNames := GetKeysFromMap(this.App.GetGlobalVariables())
                this.App.GetGlobalVariables()[this.Input.VarName] := this["ValueInput"].Text
                this.Close()
            }
            Close(){
                SetTimer(this.TimerFunc,0)
                this.Input := {}
                this.Hide()
                this.App.PopUps.GlobalVariableEditor.Run()
            }
        }
    }

}