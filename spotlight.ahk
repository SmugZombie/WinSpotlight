#SingleInstance, force
#Include, Includes\runcommand.ahk
; Spotlight for Windows
; WIP
; Ron Egli - github.com/smugzombie

app_title = WinSpotlight
app_version = 0.0.7
menu_icon := A_ScriptDir "\Includes\icon.ico"
spot_gui_background_color = 66CCFF
spot_input_gui_number = 45
spot_completion_gui_number := spot_input_gui_number + 1
spot_input_check_delay = 50
spot_completion_file := A_Temp . "\spot_completions"
spot_validation_file := A_Temp . "\spot_validation"

Menu, Tray, Tip, %app_title% - %app_version%
Menu, Tray, Icon,,,1
Menu, Tray, Icon, %menu_icon%,1,1
Menu, Tray, NoStandard
Menu, Tray, Add, R&eload, ReloadHandler
Menu, Tray, Add,
Menu, Tray, Add, E&xit, ExitHandler

Gui %spot_input_gui_number%: +Owner -Caption +AlwaysOnTop 
Gui %spot_input_gui_number%: font, s20
Gui %spot_input_gui_number%: Add, Edit, w500 vInput gspot_input_changed
Gui %spot_input_gui_number%: Color, % spot_gui_background_color
Gui %spot_input_gui_number%: +LastFound

spot_input_gui_id := winexist()

Gui %spot_completion_gui_number%: +Owner -Caption +AlwaysOnTop 
Gui %spot_completion_gui_number%: font, s14
Gui %spot_completion_gui_number%: Add, Listbox, x0 y0 w600 r10 vCompletions AltSubmit Hwndspot_Listbox
Gui %spot_completion_gui_number%: Color, EEAA99
Gui %spot_completion_gui_number%: +LastFound
WinSet, TransColor, EEAA99
return

show_spotlight:
	gosub enable_hotkeys
	Gui %spot_input_gui_number%: Show
	WinGetPos spot_input_gui_x, spot_input_gui_y, w , spot_input_gui_height, A
	spot_completion_gui_x := spot_input_gui_x
	spot_completion_gui_y := spot_input_gui_y + spot_input_gui_height + 5

^Space::
gosub show_spotlight
Return 

spot_input_changed:
  GuiControlGet spot_input, %spot_input_gui_number%:, Input
  SetTimer spot_check_input, %spot_input_check_delay%
  return

spot_check_input:
  if (A_TimeIdlePhysical < spot_input_check_delay)
    return

  SetTimer spot_check_input, off

  if (spot_input == spot_previous_input)
    return
  
  spot_previous_input := spot_input
  spot_input_len := strlen(spot_input)
  
  if (spot_input_len == 0)
  {
    gosub spot_hide_completions
    return
  }
  
  spot_matches =
	spot_input = "%spot_input%"  	
  	spot_completions := runcommand("python " A_ScriptDir "\spotlight.py --action search --query " spot_input)
  	FileAppend, %spot_completions%`n, Test.txt
    ;gosub fetchOpenWindows
  	Loop, Parse, spot_completions, CSV 
    {
      if (A_Index == 1)
        spot_user_input := A_Loopfield
      Else
        spot_matches := spot_matches . "|" . A_Loopfield
    } 

   if (spot_matches <> "|")
  {
    GuiControl %spot_completion_gui_number%:,Completions, %spot_matches%
    Gui %spot_completion_gui_number%: Show, x%spot_completion_gui_x% y%spot_completion_gui_y%
    WinActivate ahk_id %spot_input_gui_id%
    hotkey down, on
    hotkey up, on
  }
  Else
    gosub spot_hide_completions   

	return

Deref_Umlauts( w, n=1 ) { 
   While n := instr( w, "\u",1,n ) 
   StringReplace, w, w, % ww := substr( w,n,6 ), % chr( "0x" substr( ww,3 ) ), all 
   Return w 
}

copy_string_to_input(str) {
  global
  GuiControl %spot_input_gui_number%:, Input, %str%
  spot_input := str
  spot_previous_input := spot_input
  SendInput {end}
  SetTimer spot_check_input, off  
}

spot_hide_completions:
  Gui %spot_completion_gui_number%: Hide
  Hotkey down, off
  Hotkey up, off
  return

enable_hotkeys:
	Hotkey enter, spot_submit, on
	Hotkey esc, spot_cancel, on
	Hotkey down, spot_next_completion, off
	Hotkey up, spot_previous_completion, off
	return

disable_hotkeys:
	GuiControl %spot_input_gui_number%:, Input, %str%
	Hotkey enter, spot_submit, off
	Hotkey esc, spot_cancel, off
	Hotkey down, off
	Hotkey up, off
	gosub hide_guis
	return

hide_guis:
	Gui %spot_input_gui_number%: Hide
	Gui %spot_completion_gui_number%: Hide
	return

spot_submit:
  GuiControlGet spot_input, %spot_input_gui_number%:, Input
  ;gosub cleanup
  
  gosub validate_input
  return

validate_input:
	;StringReplace,spot_input,spot_input,`r`n,,A
	if (spot_input == "reload")
	{
		Reload
	}

	if (spot_input == "exit")
	{
		gosub ExitHandler
	}

	IfInString, spot_input, Google:
	{
		replace := "Google: "
		StringReplace, query, spot_input, %replace%, ,
    	Run https://www.google.com/search?q=%query% 
    	gosub disable_hotkeys
    	return
	}

	IfInString, spot_input, Windows:
	{
		replace := "Windows: "
		StringReplace, query, spot_input, %replace%, ,
    	;Run https://www.google.com/search?q=%query% 
    	send {lwin down}
		sleep 100
		send {lwin up}
		sleep 300
    	SendRaw, %query%
    	gosub disable_hotkeys
    	return
	}

	IfInString, spot_input, DigDNS:
	{
		replace := "DigDNS: "
		StringReplace, query, spot_input, %replace%, ,
    	Run http://digdns.com/?query=%query% 
    	gosub disable_hotkeys
    	return
	}

	validation = ""
	validation := runcommand("python " A_ScriptDir "\spotlight.py --action launch --query " spot_input)
	if (validation != "")
		{
			Run %validation%
  			gosub disable_hotkeys
		}
	return

spot_next_completion:
  GuiControlGet spot_current_completion, %spot_completion_gui_number%:, Completions
  if (spot_current_completion == "")
    spot_current_completion = 0
  spot_current_completion := spot_current_completion + 1
  GuiControl %spot_completion_gui_number%:Choose ,Completions, %spot_current_completion%
  gosub spot_copy_completion_to_input
  return
  
spot_previous_completion:
  GuiControlGet spot_current_completion, %spot_completion_gui_number%:, Completions
  if (spot_current_completion > 0)
  {
    spot_current_completion := spot_current_completion - 1
    if (spot_current_completion == 0)
    {
      PostMessage, 0x186, -1, 0,, ahk_id %spot_Listbox%
      copy_string_to_input(spot_user_input)
    }
    else
    {
      GuiControl %spot_completion_gui_number%:Choose ,Completions, %spot_current_completion%
      Gosub spot_copy_completion_to_input
    }
  }
  return

spot_cancel:
  gosub disable_hotkeys
  return

spot_copy_completion_to_input:
  spot_wanted_completion := spot_current_completion + 1
  Loop, Parse, spot_matches, |
  {
    if (A_Index == spot_wanted_completion)
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
reload 
return

fetchOpenWindows:
additions =
WinGet windows, List
Loop %windows%
{
  id := windows%A_Index%
  WinGetTitle wt, ahk_id %id%
  if(wt != "")
  {
    IfInString, wt, %spot_input%
    {
      ;r .= ","wt
      additions .= ","wt
    }
  }
}
spot_completions .= additions
return
