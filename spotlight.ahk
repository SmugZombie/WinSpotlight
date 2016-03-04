#SingleInstance, force
#Include, Includes\runcommand.ahk
; Spotlight for Windows
; WIP
; Ron Egli - github.com/smugzombie

app_title = WinSpotlight
app_version = 0.0.5
menu_icon := A_ScriptDir "\Includes\icon.ico"
ibc_gui_background_color = 66CCFF
ibc_input_gui_number = 45
ibc_completion_gui_number := ibc_input_gui_number + 1
ibc_input_check_delay = 100
ibc_completion_file := A_Temp . "\ibc_completions"
ibc_validation_file := A_Temp . "\ibc_validation"

Menu, Tray, Tip, %app_title% - %app_version%
Menu, Tray, Icon,,,1
Menu, Tray, Icon, %menu_icon%,1,1
Menu, Tray, NoStandard
Menu, Tray, Add, R&eload, ReloadHandler
Menu, Tray, Add,
Menu, Tray, Add, E&xit, ExitHandler

Gui %ibc_input_gui_number%: +Owner -Caption +AlwaysOnTop 
Gui %ibc_input_gui_number%: font, s20
Gui %ibc_input_gui_number%: Add, Edit, w500 vInput gibc_input_changed
Gui %ibc_input_gui_number%: Color, % ibc_gui_background_color
Gui %ibc_input_gui_number%: +LastFound

ibc_input_gui_id := winexist()

Gui %ibc_completion_gui_number%: +Owner -Caption +AlwaysOnTop 
Gui %ibc_completion_gui_number%: font, s14
Gui %ibc_completion_gui_number%: Add, Listbox, x0 y0 w600 r10 vCompletions AltSubmit HwndIbc_Listbox
Gui %ibc_completion_gui_number%: Color, EEAA99
Gui %ibc_completion_gui_number%: +LastFound
WinSet, TransColor, EEAA99
return

show_spotlight:
	gosub enable_hotkeys
	Gui %ibc_input_gui_number%: Show
	WinGetPos ibc_input_gui_x, ibc_input_gui_y, w , ibc_input_gui_height, A
	ibc_completion_gui_x := ibc_input_gui_x
	ibc_completion_gui_y := ibc_input_gui_y + ibc_input_gui_height + 5

^Space::
gosub show_spotlight
Return 

ibc_input_changed:
  GuiControlGet ibc_input, %ibc_input_gui_number%:, Input
  SetTimer ibc_check_input, %ibc_input_check_delay%
  return

ibc_check_input:
  if (A_TimeIdlePhysical < ibc_input_check_delay)
    return

  SetTimer ibc_check_input, off

  if (ibc_input == ibc_previous_input)
    return
  
  ibc_previous_input := ibc_input
  ibc_input_len := strlen(ibc_input)
  
  if (ibc_input_len == 0)
  {
    gosub ibc_hide_completions
    return
  }
  
  ibc_matches =
	ibc_input = "%ibc_input%"  	
  	ibc_completions := runcommand("python " A_ScriptDir "\spotlight.py --action search --query " ibc_input)
  	FileAppend, %ibc_completions%`n, Test.txt

  	Loop, Parse, ibc_completions, CSV 
    {
      if (A_Index == 1)
        ibc_user_input := A_Loopfield
      Else
        ibc_matches := ibc_matches . "|" . A_Loopfield
    } 

   if (ibc_matches <> "|")
  {
    GuiControl %ibc_completion_gui_number%:,Completions, %ibc_matches%
    Gui %ibc_completion_gui_number%: Show, x%ibc_completion_gui_x% y%ibc_completion_gui_y%
    WinActivate ahk_id %ibc_input_gui_id%
    hotkey down, on
    hotkey up, on
  }
  Else
    gosub ibc_hide_completions   

	return

Deref_Umlauts( w, n=1 ) { 
   While n := instr( w, "\u",1,n ) 
   StringReplace, w, w, % ww := substr( w,n,6 ), % chr( "0x" substr( ww,3 ) ), all 
   Return w 
}

copy_string_to_input(str) {
  global
  GuiControl %ibc_input_gui_number%:, Input, %str%
  ibc_input := str
  ibc_previous_input := ibc_input
  SendInput {end}
  SetTimer ibc_check_input, off  
}

ibc_hide_completions:
  Gui %ibc_completion_gui_number%: Hide
  Hotkey down, off
  Hotkey up, off
  return

enable_hotkeys:
	Hotkey enter, ibc_submit, on
	Hotkey esc, ibc_cancel, on
	Hotkey down, ibc_next_completion, off
	Hotkey up, ibc_previous_completion, off
	return

disable_hotkeys:
	GuiControl %ibc_input_gui_number%:, Input, %str%
	Hotkey enter, ibc_submit, off
	Hotkey esc, ibc_cancel, off
	Hotkey down, off
	Hotkey up, off
	gosub hide_guis
	return

hide_guis:
	Gui %ibc_input_gui_number%: Hide
	Gui %ibc_completion_gui_number%: Hide
	return

ibc_submit:
  GuiControlGet ibc_input, %ibc_input_gui_number%:, Input
  ;gosub cleanup
  
  gosub validate_input
  return

validate_input:
	;StringReplace,ibc_input,ibc_input,`r`n,,A
	if (ibc_input == "reload")
	{
		Reload
	}

	if (ibc_input == "exit")
	{
		gosub ExitHandler
	}

	IfInString, ibc_input, Google:
	{
		replace := "Google: "
		StringReplace, query, ibc_input, %replace%, ,
    	Run https://www.google.com/search?q=%query% 
    	gosub disable_hotkeys
    	return
	}

	IfInString, ibc_input, Windows:
	{
		replace := "Windows: "
		StringReplace, query, ibc_input, %replace%, ,
    	;Run https://www.google.com/search?q=%query% 
    	send {lwin down}
		sleep 100
		send {lwin up}
		sleep 300
    	SendRaw, %query%
    	gosub disable_hotkeys
    	return
	}

	validation = ""
	validation := runcommand("python " A_ScriptDir "\spotlight.py --action launch --query " ibc_input)
	if (validation != "")
		{
			Run %validation%
  			gosub disable_hotkeys
		}
	return

ibc_next_completion:
  GuiControlGet ibc_current_completion, %ibc_completion_gui_number%:, Completions
  if (ibc_current_completion == "")
    ibc_current_completion = 0
  ibc_current_completion := ibc_current_completion + 1
  GuiControl %ibc_completion_gui_number%:Choose ,Completions, %ibc_current_completion%
  gosub ibc_copy_completion_to_input
  return
  
ibc_previous_completion:
  GuiControlGet ibc_current_completion, %ibc_completion_gui_number%:, Completions
  if (ibc_current_completion > 0)
  {
    ibc_current_completion := ibc_current_completion - 1
    if (ibc_current_completion == 0)
    {
      PostMessage, 0x186, -1, 0,, ahk_id %Ibc_Listbox%
      copy_string_to_input(ibc_user_input)
    }
    else
    {
      GuiControl %ibc_completion_gui_number%:Choose ,Completions, %ibc_current_completion%
      Gosub ibc_copy_completion_to_input
    }
  }
  return

ibc_cancel:
  gosub disable_hotkeys
  return

ibc_copy_completion_to_input:
  ibc_wanted_completion := ibc_current_completion + 1
  Loop, Parse, ibc_matches, |
  {
    if (A_Index == ibc_wanted_completion)
    {
      copy_string_to_input(A_Loopfield)
      Break
    }
  }
  return

ExitHandler:
ExitApp 
return

ReloadHandler:
Reload 
return
