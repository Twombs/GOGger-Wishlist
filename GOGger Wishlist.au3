;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                       ;;
;;  AutoIt Version: 3.3.14.2                                                             ;;
;;                                                                                       ;;
;;  Template AutoIt script.                                                              ;;
;;                                                                                       ;;
;;  AUTHOR:  Timboli <thsaint@ihug.com.au>                                               ;;
;;                                                                                       ;;
;;  SCRIPT FUNCTION:   Program to view user GoG Wishlist entries (prices, sorting, etc)  ;;
;;                                                                                       ;;
;;  ADAPTION:  Formerly GetGOG Wishlist, but modified and adapted to meet GOG changes    ;;
;;                                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; FUNCTIONS
; CheckForTwoDecimalPlaces($value), CreateBackupListFiles($gamefle), DisableEnableControls($state)
; LoadTheList(), SetTheColumnWidths()

#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ListViewConstants.au3>
#include <GuiListView.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <Misc.au3>
#include <String.au3>
#include <Inet.au3>
#include <File.au3>
#include <IE.au3>
#include <Date.au3>
#include <WinAPI.au3>
#include <Array.au3>

_Singleton("gog-ger-wishlist-thsaint", 0)

Global $Button_add, $Button_check, $Button_detail, $Button_find, $Button_info, $Button_ontop, $Button_remove, $Button_update
Global $Button_urlup, $Button_web, $Checkbox_all, $Checkbox_clip, $Checkbox_next, $Checkbox_stop, $Group_list, $Input_cc
Global $Input_id, $Input_price, $Input_title, $Input_user, $Label_cc, $Label_id, $Label_time, $Label_user, $Label_id
Global $Listview_items

Global $absent, $added, $ans, $backups, $base, $bigid, $cc, $changed, $check, $checked, $close, $colnum, $color, $currency
Global $current, $database, $date, $e, $err, $error, $exist, $extras, $failed, $failure, $flag, $fle, $found, $game, $gamefle
Global $gameID, $games, $gethtml, $height, $high, $html, $inifle, $l, $last, $left, $line, $lines, $link, $lne, $logfle, $low
Global $lowid, $lvtop, $message, $missing, $n, $nums, $ontop, $page, $ping, $price, $prior, $pth, $query, $read, $reduce
Global $reload, $removed, $res, $Scriptname, $show, $slick, $start, $state, $status, $surplus, $text, $title, $titles, $top
Global $total, $URL, $user, $v, $value, $version, $wait, $webfle, $webpage, $WishlistGUI

$backups = @ScriptDir & "\Backups"
$gamefle = @ScriptDir & "\Games.ini"
$inifle = @ScriptDir & "\Options.ini"
$logfle = @ScriptDir & "\Log.txt"
$Scriptname = "GOGger Wishlist v1.3"
$version = "(updated in September 2021)"
$webfle = @ScriptDir & "\Html.txt"

If Not FileExists($backups) Then DirCreate($backups)

$database = IniRead($inifle, "Games List", "path", "")
If $database = "" Then
	$value = "GOGger Wishlist\"
	If @Compiled Then
		$value = $value & "GOGger Wishlist.exe"
	Else
		$value = $value & "GOGger Wishlist.au3"
	EndIf
	$database = StringReplace(@ScriptFullPath, $value, "")
	$value = $database & "GOG-CLI\Games.ini"
	If FileExists($value) Then
		$database = $value
		IniWrite($inifle, "Games List", "path", $database)
	Else
		$database = ""
	EndIf
EndIf

$height = 430
$base = $height - 30
$left = IniRead($inifle, "Program Window", "left", -1)
If $left > (@DesktopWidth - 806) Then
	$left = (@DesktopWidth - 806)
	IniWrite($inifle, "Program Window", "left", $left)
ElseIf $left > (@DesktopWidth - (806 + 6)) Then
	$left = (@DesktopWidth - (806 + 6))
	IniWrite($inifle, "Program Window", "left", $left)
ElseIf $left < -1 Then
	$left = 2
	IniWrite($inifle, "Program Window", "left", $left)
ElseIf $left < (-1 + 6) Then
	$left = 2 + 6
	IniWrite($inifle, "Program Window", "left", $left)
EndIf
$top = IniRead($inifle, "Program Window", "top", -1)
;If $top > (@DesktopHeight - 565) Then
;	$top = (@DesktopHeight - 565)
If $top > (@DesktopHeight - ($height + 35)) Then
	$top = (@DesktopHeight - ($height + 35))
	IniWrite($inifle, "Program Window", "top", $top)
ElseIf $top < -1 Then
	$top = 2
	IniWrite($inifle, "Program Window", "top", $top)
EndIf
$WishlistGUI = GuiCreate($Scriptname, 910, $height, $left, $top, $WS_OVERLAPPED + $WS_CAPTION _
							+ $WS_SYSMENU + $WS_CLIPSIBLINGS + $WS_VISIBLE + $WS_MINIMIZEBOX, $WS_EX_TOPMOST)
; CONTROLS
$Label_time = GUICtrlCreateLabel("", 340, 0, 300, 17, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
GUICtrlSetFont($Label_time, 7, 600, 0, "Small Fonts")
GUICtrlSetBkColor($Label_time, $COLOR_BLUE)
GUICtrlSetColor($Label_time, 0xF0F030)
GUICtrlSetState($Label_time, $GUI_HIDE)
;
$Group_list = GuiCtrlCreateGroup("List Of Games On Wishlist", 10, 10, 890, 380)
$Input_title = GUICtrlCreateInput("", 20, 28, 403, 20)
GUICtrlSetTip($Input_title, "Selected entry title!")
$Button_find = GuiCtrlCreateButton("FIND", 426, 27, 50, 21)
GUICtrlSetFont($Button_find, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_find, "Find the specified text!")
$Input_price = GUICtrlCreateInput("", 480, 28, 50, 20)
GUICtrlSetTip($Input_price, "Selected entry current price!")
$Button_web = GuiCtrlCreateButton("WEB PAGE", 535, 27, 75, 21)
GUICtrlSetFont($Button_web, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_web, "Go to web page for selected title!")
;
$Checkbox_clip = GUICtrlCreateCheckbox("C", 615, 27, 15, 21, $BS_AUTO3STATE)
GUICtrlSetTip($Checkbox_clip, "Copy URL to clipboard for selected!")
;
$Button_remove = GuiCtrlCreateButton("REMOVE", 640, 27, 65, 21)
GUICtrlSetFont($Button_remove, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_remove, "Remove a game from the list!")
;
$Button_update = GuiCtrlCreateButton("UPDATE", 715, 27, 65, 21)
GUICtrlSetFont($Button_update, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_update, "Update & Load the Local games list!")
;
$Checkbox_stop = GUICtrlCreateCheckbox("Stop", 785, 28, 40, 20)
GUICtrlSetTip($Checkbox_stop, "Stop the Update as soon as possible!")
;
$Button_ontop = GUICtrlCreateCheckbox("ON TOP", 835, 25, 55, 23, $BS_PUSHLIKE)
GUICtrlSetFont($Button_ontop, 6, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_ontop, "Toggle the On Top setting!")
;
$Button_check = GuiCtrlCreateButton("CHECK PRICE", 10, $base - 1, 85, 22)
GUICtrlSetFont($Button_check, 6, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_check, "Check price of one selected entry!")
$Checkbox_next = GUICtrlCreateCheckbox("Next", 100, $base, 40, 20)
GUICtrlSetTip($Checkbox_next, "Move to next entry after query!")
$Checkbox_all = GUICtrlCreateCheckbox("ALL", 145, $base, 35, 20)
GUICtrlSetTip($Checkbox_all, "Check the price of ALL entries during a query!")
;
$Label_id = GUICtrlCreateLabel("Game ID", 190, $base, 65, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
GUICtrlSetFont($Label_id, 7, 600, 0, "Small Fonts")
GUICtrlSetBkColor($Label_id, 0x000000)
GUICtrlSetColor($Label_id, 0xF0F030)
$Input_id = GUICtrlCreateInput("", 255, $base, 80, 20)
GUICtrlSetTip($Input_id, "GOG ID of selected game!")
;
$Label_cc = GUICtrlCreateLabel("CC", 345, $base, 30, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
GUICtrlSetFont($Label_cc, 7, 600, 0, "Small Fonts")
GUICtrlSetBkColor($Label_cc, 0x000000)
GUICtrlSetColor($Label_cc, 0xF0F030)
$Input_cc = GUICtrlCreateInput("", 375, $base, 35, 20)
GUICtrlSetTip($Input_cc, "Country Code!")
;
$Label_user = GUICtrlCreateLabel("Username", 420, $base, 70, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
GUICtrlSetFont($Label_user, 7, 600, 0, "Small Fonts")
GUICtrlSetBkColor($Label_user, 0x000000)
GUICtrlSetColor($Label_user, 0xF0F030)
$Input_user = GUICtrlCreateInput("", 490, $base, 70, 20)
GUICtrlSetTip($Input_user, "GOG account username or PC username!")
;
$Button_add = GuiCtrlCreateButton("ADD GAME", 570, $base - 1, 85, 22)
GUICtrlSetFont($Button_add, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_add, "Add a game to the wishlist!")
;
$Button_urlup = GuiCtrlCreateButton("UPDATE THE URL", 665, $base - 1, 115, 21)
GUICtrlSetFont($Button_urlup, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_urlup, "Make changes to the stored URL!")
;
$Button_detail = GuiCtrlCreateButton("DETAIL", 790, $base - 1, 60, 21)
GUICtrlSetFont($Button_detail, 7, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_detail, "Detail for selected game!")
;
$Button_info = GuiCtrlCreateButton("INFO", 860, $base - 1, 40, 21)
GUICtrlSetFont($Button_info, 6, 600, 0, "Small Fonts")
GUICtrlSetTip($Button_info, "Information about the program!")
;
$lvtop = 52
$Listview_items = GUICtrlCreateListView("No.|Title|Start|Low|High|Prior|Price|URL", 20, $lvtop, 870, 328, _
										$GUI_SS_DEFAULT_LISTVIEW, $LVS_EX_FULLROWSELECT + $LVS_EX_GRIDLINES)
SetTheColumnWidths()
; Pale Green
GUICtrlSetBkColor($Listview_items, 0xC0F0C0)
GUICtrlSetTip($Listview_items, "List of items!")
;
; OS SETTINGS
;
; SETTINGS
$lowid = $Listview_items
;
$slick = IniRead($inifle, "List Loading", "slick", "")
If $slick = "" Then
	$slick = 1
	IniWrite($inifle, "List Loading", "slick", $slick)
EndIf
;
$cc = IniRead($inifle, "Country", "code", "")
If $cc = "" Then
	$cc = "AUD"
	IniWrite($inifle, "Country", "code", $cc)
EndIf
GUICtrlSetData($Input_cc, $cc)
;
$user = IniRead($inifle, "GOG", "username", "")
If $user = "" Then
	$user = @UserName
	IniWrite($inifle, "GOG", "username", $user)
EndIf
GUICtrlSetData($Input_user, $user)
;
$currency = IniRead($inifle, "GOG Wishlist", "currency", "")
If $currency = "" Then
	$currency = "$"
	$currency = InputBox("Currency Query", "Please entry your currency symbol.", $currency, "", 210, 130, Default, Default, 0, $WishlistGUI)
	If @error = 0 Then
		IniWrite($inifle, "GOG Wishlist", "currency", $currency)
	EndIf
EndIf
;
$ontop = IniRead($inifle, "Program Window", "on_top", "")
If $ontop = "" Then
	$ontop = 1
	IniWrite($inifle, "Program Window", "on_top", $ontop)
EndIf
GUICtrlSetState($Button_ontop, $ontop)
If $ontop = 4 Then WinSetOnTop($WishlistGUI, "", 0)
;
If FileExists($gamefle) Then
	GUICtrlSetData($Input_title, "Please Wait - Loading List")
	GUICtrlSetBkColor($Input_title, 0xFF0000)
	If $slick = 1 Then
		GUISetState($WishlistGUI, @SW_DISABLE)
		_GUICtrlListView_BeginUpdate($Listview_items)
	Else
		GUISetState($WishlistGUI, @SW_DISABLE)
	EndIf
	LoadTheList()
	If $slick = 1 Then
		_GUICtrlListView_EndUpdate($Listview_items)
		GUISetState($WishlistGUI, @SW_ENABLE)
	Else
		GUISetState($WishlistGUI, @SW_ENABLE)
	EndIf
	GUICtrlSetData($Input_title, "")
	GUICtrlSetBkColor($Input_title, Default)
EndIf
;
$date = ""
;
CreateBackupListFiles($gamefle)


GuiSetState(@SW_SHOW)
While 1
	$msg = GuiGetMsg()
	Select
	Case $msg = $GUI_EVENT_CLOSE
		; Quit, Close or Exit program
		$winpos = WinGetPos($WishlistGUI, "")
		$left = $winpos[0]
		If $left < 0 Then
			$left = 2
		ElseIf $left > @DesktopWidth - $winpos[2] Then
			$left = @DesktopWidth - $winpos[2]
		EndIf
		IniWrite($inifle, "Program Window", "left", $left)
		$top = $winpos[1]
		If $top < 0 Then
			$top = 2
		ElseIf $top > @DesktopHeight - $winpos[3] Then
			$top = @DesktopHeight - $winpos[3]
		EndIf
		IniWrite($inifle, "Program Window", "top", $top)
		;
		$cc = GUICtrlRead($Input_cc)
		If $cc <> IniRead($inifle, "Country", "code", "") Then
			IniWrite($inifle, "Country", "code", $cc)
		EndIf
		;
		$user = GUICtrlRead($Input_user)
		If $user <> IniRead($inifle, "GOG", "username", "") Then
			IniWrite($inifle, "GOG", "username", $user)
		EndIf
		;
		GUIDelete($WishlistGUI)
		ExitLoop
	Case $msg = $Button_web
		; Go to web page for selected title
		$buttxt = GUICtrlRead($Button_web)
		If $buttxt <> "WISHLIST" Then
			$e = _GUICtrlListView_GetSelectedIndices($Listview_items, True)
			If $e[0] = 1 Then
				$e = $e[1]
			EndIf
		EndIf
		If $e > -1 Or $buttxt = "WISHLIST" Then
			If $buttxt <> "WISHLIST" Then
				$link = _GUICtrlListView_GetItemText($Listview_items, $e, 7)
				$link = "https://www.gog.com" & $link
			EndIf
			If $buttxt = "WEB PAGE" Then
				ShellExecute($link)
			ElseIf $buttxt = "WISHLIST" Then
				$URL = "https://www.gog.com/u/" & $user & "/wishlist"
				$text = InputBox("Go To Wishlist", "Please check your wishlist URL.", $URL, "", 280, 130, Default, Default, 0, $WishlistGUI)
				If @error = 0 And StringLeft($text, 4) = "http" Then
					ShellExecute($URL)
				ElseIf StringLeft($text, 4) <> "http" Then
					MsgBox(262192, "Link Error", "URL has not been correctly specified!", 0, $WishlistGUI)
				EndIf
			Else
				ClipPut($link)
			EndIf
		EndIf
		GUICtrlSetState($Label_time, $GUI_HIDE)
	Case $msg = $Button_urlup
		; Make changes to the stored URL
		If $title <> "" And $e > -1 Then
			$link = IniRead($gamefle, $title, "url", "")
			If $link = "" Then $link = ClipGet()
			$val = InputBox("Update Selected Entry (" & $e & ")", "Modify the URL for - " & $title, $link, "", 500, 130, Default, Default, 0, $WishlistGUI)
			If @error = 0 And $val <> "" Then
				$link = $val
				If StringLeft($link, 4) = "http" Then
					$link = StringSplit($link, "//www.gog.com", 1)
					If $link[0] > 1 Then
						$link = $link[2]
					Else
						$link = ""
					EndIf
				ElseIf StringLeft($link, 6) <> "/game/" Then
					$link = ""
				EndIf
				IniWrite($gamefle, $title, "url", $link)
				_GUICtrlListView_SetItemText($Listview_items, $e, $link, 7)
			EndIf
		Else
			MsgBox(262192, "Selection Error", "Entry is not selected correctly!", 0, $WishlistGUI)
		EndIf
		GUICtrlSetState($Label_time, $GUI_HIDE)
	Case $msg = $Button_update
		; Update the wishlist by comparing with a local games list database (if one exists)
		; Typically this is a list of games now owned and no longer need to be on the wishlist.
		; Currently supported database, is the 'Games.ini' file used by my GOGcli GUI program.
		$ans = MsgBox(262179, "Update The Wishlist - " & $user, _
			"This program involves manual ADD or Remove," & @LF & _
			"but can have some level of automated removal" & @LF & _
			"if my GOGcli GUI program is also in use. This is" & @LF & _
			"removal of games that no longer need to be on" & @LF & _
			"the wishlist, because they have been purchased." & @LF & @LF & _
			"NOTE - Removal requires each GOG Game ID." & @LF & @LF & _
			"YES = Continue with the removal process." & @LF & _
			"NO = Continue with a correction choice." & @LF & _
			"CANCEL = Abort.", 0, $WishlistGUI)
		If $ans = 6 Then
			; Remove purchased games from wishlist.
			If $database = "" Or Not FileExists($database) Then
				$pth = FileOpenDialog("Select the 'GOGcli GUI' program's 'Games.ini' file.", "", "Games file (*.ini)", 3, $database, $WishlistGUI)
				If @error <> 1 And StringMid($pth, 2, 2) = ":\" Then
					$database = $pth
					IniWrite($inifle, "Games List", "path", $database)
				Else
					$database = ""
				EndIf
			EndIf
			If $database <> "" Then
				DisableEnableControls($GUI_DISABLE)
				GUICtrlSetState($Checkbox_next, $GUI_DISABLE)
				GUICtrlSetState($Checkbox_all, $GUI_DISABLE)
				GUICtrlSetData($Input_title, "Please Wait - Checking Lists")
				GUICtrlSetBkColor($Input_title, $COLOR_LIME)
				GUICtrlSetState($Label_time, $GUI_SHOW)
				$status = "Started at " & _NowTime()
				GUICtrlSetData($Label_time, $status)
				$removed = 0
				If $e < 0 Then
					$v = 0
				Else
					$v = $e
				EndIf
				$nums = _GUICtrlListView_GetItemCount($Listview_items)
				For $e = $v to $nums - 1
					_GUICtrlListView_EnsureVisible($Listview_items, $e, False)
					_GUICtrlListView_SetItemSelected($Listview_items, $e, True, True)
					$title = _GUICtrlListView_GetItemText($Listview_items, $e, 1)
					_GUICtrlListView_ClickItem($Listview_items, $e, "right", False, 1, 1)
					$reduce = ""
					If $title <> "" Then
						$gameID = IniRead($gamefle, $title, "id", "")
						If $gameID <> "" Then
							$game = IniRead($database, $gameID, "title", "")
							If $game <> "" Then
								$ans = MsgBox(262179, "Wishlist Removal", _
									"Bought = " & $game & @LF & _
									"Title = " & $title & @LF & _
									"Game ID = " & $gameID & @LF & @LF & _
									"YES = Remove selected title." & @LF & _
									"NO = Skip & Continue." & @LF & _
									"CANCEL = Abort Removals.", 0, $WishlistGUI)
								If $ans = 6 Then
									IniDelete($gamefle, $title)
									_GUICtrlListView_DeleteItem($Listview_items, $e)
									GUICtrlSetData($Input_title, "")
									GUICtrlSetData($Input_price, "")
									GUICtrlSetData($Input_id, "")
									$nums = $nums - 1
									GUICtrlSetData($Group_list, "List Of Games On Wishlist  (" & $nums & ")")
									$bigid = $lowid + $nums + 1
									$removed = $removed + 1
									If $e < $nums Then $reduce = 1
								ElseIf $ans = 2 Then
									$show = 1
									_GUICtrlListView_ClickItem($Listview_items, $e, "left", False, 1, 1)
									ExitLoop
								EndIf
							EndIf
						EndIf
					EndIf
					If GUICtrlRead($Checkbox_stop) = $GUI_CHECKED Then
						$show = 1
						_GUICtrlListView_ClickItem($Listview_items, $e, "left", False, 1, 1)
						ExitLoop
					EndIf
					If $reduce = 1 Then
						;$v = $e
						$e = $e - 1
					EndIf
					Sleep(200)
				Next
				If $removed > 0 Then
					GUICtrlSetData($Input_title, "Please Wait - Reloading List")
					GUICtrlSetBkColor($Input_title, 0xFF0000)
					If $slick = 1 Then
						GUISetState($WishlistGUI, @SW_DISABLE)
						_GUICtrlListView_BeginUpdate($Listview_items)
					EndIf
					_GUICtrlListView_DeleteAllItems($Listview_items)
					LoadTheList()
					If $slick = 1 Then
						_GUICtrlListView_EndUpdate($Listview_items)
						GUISetState($WishlistGUI, @SW_ENABLE)
					EndIf
				EndIf
				$status = $status & " and Finished at " & _NowTime()
				GUICtrlSetData($Label_time, $status)
				GUICtrlSetData($Input_title, "")
				GUICtrlSetBkColor($Input_title, Default)
				DisableEnableControls($GUI_ENABLE)
				GUICtrlSetState($Checkbox_next, $GUI_ENABLE)
				GUICtrlSetState($Checkbox_all, $GUI_ENABLE)
			EndIf
		ElseIf $ans = 7 Then
			; A choice of fixing missing prices (or correcting them), or comparing
			; existing program entries with your online GOG Wishlist entries.
			$ans = MsgBox(262179, "Correction Choice", _
				"YES = Check to ADD or Remove entries." & @LF & _
				"NO = Check to Fix or ADD missing prices." & @LF & _
				"CANCEL = Abort any corrections." & @LF & @LF & _
				"NOTE - 'Stop' checkbox can be used with YES.", 0, $WishlistGUI)
			If $ans = 6 Then
				; Compare existing program entries with your online GOG Wishlist entries.
				$ans = MsgBox(262209, "Compare Query", _
					"The following might be needed now and then, due" & @LF & _
					"to program wishlist entries getting out of sync with" &  @LF & _
					"online GOG Wishlist entries." & @LF & @LF & _
					"This process involves scanning saved GOG wishlist" &  @LF & _
					"web page(s), and comparing what exists there to" & @LF & _
					"what exists in this program's database." & @LF & @LF & _
					"NOTE - You need to have saved the page(s) first," & @LF & _
					"before continuing with their processing here." & @LF & @LF & _
					"First thing the process does, is compare all entries," & @LF & _
					"building both ADD and REMOVE lists, which if they" & @LF & _
					"exist, are then presented to be dealt with, one entry" & @LF & _
					"at a time." & @LF & @LF & _
					"OK = Contine with the compare process." & @LF & _
					"CANCEL = Abort comparing.", 0, $WishlistGUI)
				If $ans = 1 Then
					DisableEnableControls($GUI_DISABLE)
					GUICtrlSetState($Checkbox_next, $GUI_DISABLE)
					GUICtrlSetState($Checkbox_all, $GUI_DISABLE)
					GUICtrlSetData($Input_title, "Please Wait - Selecting Web Page")
					GUICtrlSetBkColor($Input_title, $COLOR_RED)
					$auto = ""
					$page = 0
					While 1
						$page = $page + 1
						If $auto = 1 Then
							$pos = StringInStr($webpage, "_", 0, -1)
							If $pos > 0 Then
								$webpage = StringLeft($webpage, $pos) & $page & ".html"
								If Not FileExists($webpage) Then
									$page = $page - 1
									$webpage = ""
								EndIf
							EndIf
						Else
							$webpage = IniRead($inifle, "Wishlist Web Page", "path", "")
							$pth = FileOpenDialog("Select a saved Wishlist web page file. (Page " & $page & ")", "", "Saved HTML file (*.html;*.htm)", 3, $webpage, $WishlistGUI)
							If @error <> 1 And StringMid($pth, 2, 2) = ":\" Then
								$webpage = $pth
								IniWrite($inifle, "Wishlist Web Page", "path", $webpage)
							Else
								$webpage = ""
							EndIf
						EndIf
						If $webpage = "" Then
							ExitLoop
						Else
							GUICtrlSetData($Input_title, "Please Wait - Reading Web Page")
							GUICtrlSetBkColor($Input_title, $COLOR_LIME)
							; First we need to remove previous indicator marks from the 'Games.ini' file.
							; Needs to be via a query, and occur only once per set of saved pages.
							If $auto = "" Then
								If $page = 1 Then
									$flag = 262209
								Else
									$flag = 262209 + 256
								EndIf
								$ans = MsgBox($flag, "Start Query - Page " & $page, _
									"Is this the first of multiple pages?" & @LF & @LF & _
									"With the first page, we want previous" &  @LF & _
									"processing markers to be removed." & @LF & @LF & _
									"NOTE - If you have closed this program" & @LF & _
									"since the first page has been processed" & @LF & _
									"then you really need to start over." & @LF & @LF & _
									"OK = Yes the first." & @LF & _
									"CANCEL = Not the first.", 0, $WishlistGUI)
								If $ans = 1 Then
									_ReplaceStringInFile($gamefle, "exists=yes", "exists=")
									$exist = 0
									$found = 0
									$missing = 0
									If StringRight($webpage, 7) = "_1.html" Then
										$ans = MsgBox($flag, "Auto Increment Query", _
											"Are any remaining pages numbered consecutively?" & @LF & @LF & _
											"That means the next page ends in '_2.html'," &  @LF & _
											"and any following one would be '_3.html'," &  @LF & _
											"and so on." & @LF & @LF & _
											"If so, then they can be selected for you." & @LF & @LF & _
											"OK = Yes they are consecutive." & @LF & _
											"CANCEL = Not the first.", 0, $WishlistGUI)
										If $ans = 1 Then
											$auto = 1
										EndIf
									EndIf
								EndIf
							EndIf
							$read = FileRead($webpage)
							$lines = StringSplit($read, 'product.title">', 1)
							$games = $lines[0]
							For $l = 2 to $games
								$line = $lines[$l]
								$title = $line
								$title = StringSplit($title, '</span>', 1)
								$title = $title[1]
								$title = StringReplace($title, '\u00ae', '')
								$title = StringReplace($title, '\u2122', '')
								$title = StringReplace($title, '\u2013', '-')
								$title = StringReplace($title, "\u2019", "'")
								$title = StringReplace($title, "&amp;", "&")
								;$title = StringReplace($title, "®", "")
								;$title = StringReplace($title, "™", "")
								;$title = StringReplace($title, "’", "'")
								;$title = StringStripWS($title, 7)
								If $title <> "" Then
									$found = $found + 1
									If IniRead($gamefle, $title, "last", "") = "" Then
										$missing = $missing + 1
										$absent = $title
									Else
										; Mark as existing for final check.
										IniWrite($gamefle, $title, "exists", "yes")
										$exist = $exist + 1
									EndIf
									;MsgBox(262192, "Title", $title, 0, $WishlistGUI)
								EndIf
								;If $l = 5 Then ExitLoop
								If GUICtrlRead($Checkbox_stop) = $GUI_CHECKED Then ExitLoop
							Next
							$games = $games - 1
							MsgBox(262192, "Read Result - Page " & $page, $games & " games found in current page.", 3, $WishlistGUI)
							Sleep(500)
							If GUICtrlRead($Checkbox_stop) = $GUI_CHECKED Then ExitLoop
						EndIf
					WEnd
					$ans = MsgBox(262209, "Finished Query", _
						$page & " pages processed." & @LF & @LF & _
						"Are you ready to see the results?" & @LF & @LF & _
						"That would be yes if the last (or only) " & @LF & _
						"saved web page has been processed." & @LF & @LF & _
						"If yes, then the results will be collated" & @LF & _
						"and presented for more processing if" & @LF & _
						"that is indicated." & @LF & @LF & _
						"OK = Yes the last, show results." & @LF & _
						"CANCEL = Not the last.", 0, $WishlistGUI)
					If $ans = 1 Then
						If $found > 0 Then
							$reload = ""
							$message = "A total of " & $found & " games was found in saved web page(s)."
							If $missing > 0 Then
								If $missing = 1 Then
									$absent = $absent & @LF & @LF
								Else
									$absent = ""
								EndIf
								$missing = $missing & " games are missing from the program database, that exist" & @LF & _
								"on your online GOG Wishlist." & @LF & @LF & $absent & _
								"To remedy this issue, you can use the ADD GAME button's" & @LF & _
								"Multiple ADD games option."
								$message = $message & @LF & @LF & $missing
							EndIf
							If $exist > 0 Then
								$exist = $exist & " matches exist in the program database and online wishlist."
								$message = $message & @LF & @LF & $exist
								GUICtrlSetData($Input_title, "Please Wait - Checking Database")
								GUICtrlSetBkColor($Input_title, $COLOR_RED)
								$extras = ""
								$games = IniReadSectionNames($gamefle)
								For $n = 1 To $games[0]
									$title = $games[$n]
									$value = IniRead($gamefle, $title, "exists", "no")
									If $value = "no" Or $value = "" Then
										If $extras = "" Then
											$extras = $title
										Else
											$extras = $extras & @CRLF & $title
										EndIf
									EndIf
								Next
								$games = $games[0]
								$message = $message & @LF & @LF & $games & " games exist in the 'GOGger Wishlist' program database."
							EndIf
							GUICtrlSetData($Input_title, "Please Wait - Showing Results")
							GUICtrlSetBkColor($Input_title, $COLOR_LIME)
							If $extras <> "" Then
								$surplus = @ScriptDir & "\Surplus.txt"
								_FileCreate($surplus)
								FileWrite($surplus, "You may now own one or more (or all) of the following." & @CRLF & @CRLF & $extras)
								ShellExecute($surplus)
								$message = $message & @LF & @LF & "Some games exist only in this program's database."
								$message = $message & @LF & @LF & "A text file called 'Surplus.txt' should have opened. It should"
								$message = $message & @LF & "show a list of games not found in your online GOG wishlist."
								$message = $message & @LF & @LF & "You may now own one or more (or all) of those games."
								$message = $message & @LF & @LF & "Do you want to step through a removal process?"
								$message = $message & @LF & @LF & "NOTE - You could instead, manually remove entries, but"
								$message = $message & @LF & "clicking OK will be quicker and easier."
								$message = $message & @LF & @LF & "ADVICE - If you use my 'GOGcli GUI' program, then using"
								$message = $message & @LF & "this program's UPDATE button's first choice, might be a"
								$message = $message & @LF & "better option than clicking on OK. That should have been"
								$message = $message & @LF & "donefirst, before using this current process."
								$message = $message & @LF & @LF & "OK = Query each title for removal."
							Else
								$message = $message & @LF & @LF & "OK = Continue."
							EndIf
							$ans = MsgBox(262209, "Comparison Results", _
								$message & @LF & "CANCEL = Exit.", 0, $WishlistGUI)
							If $ans = 1 And $extras <> "" Then
								GUICtrlSetData($Input_title, "Please Wait - Removing Selected")
								GUICtrlSetBkColor($Input_title, $COLOR_RED)
								$extras = StringSplit($extras, @CRLF, 1)
								$total = $extras[0]
								For $1 = 1 To $total
									$title = $extras[$1]
									$ans = MsgBox(262211, "Removal Query (" & $1 & " of " & $total & ")", _
										"Remove the following game title from the list?" & @LF & @LF & _
										$title & @LF & @LF & _
										"YES = Remove the title." & @LF & _
										"NO = Skip to next title." & @LF & _
										"CANCEL = Abort any removals.", 0, $WishlistGUI)
									If $ans = 6 Then
										$reload = 1
										IniDelete($gamefle, $title)
										$games = $games - 1
									ElseIf $ans = 2 Then
										ExitLoop
									EndIf
								Next
							EndIf
							If $found < $games Then
								$titles = $games
								$ans = MsgBox(262209, "Duplicates Query", _
									"Database (" & $games & "). Wishlist (" & $found & ")." & @LF & @LF & _
									"Despite any removals, that may have occurred" & @LF & _
									"(or not), numbers just don't add up, as there is" & @LF & _
									"more games listed in the program's database," & @LF & _
									"than there are on your online GOG Wishlist." & @LF & @LF & _
									"Sometimes duplicates do occur in the database," & @LF & _
									"possibly due to uncommon characters (® etc)." & @LF & @LF & _
									"Do you want to check for duplicates?" & @LF & @LF & _
									"You will get a removal query for any found." & @LF & @LF & _
									"OK = Check for any duplicates." & @LF & _
									"CANCEL = Abort checking for duplicates.", 0, $WishlistGUI)
								If $ans = 1 Then
									GUICtrlSetData($Input_title, "Please Wait - Checking For Duplicates")
									GUICtrlSetBkColor($Input_title, $COLOR_LIME)
									$read = FileRead($gamefle)
									If $read <> "" Then
										$removed = 0
										$games = IniReadSectionNames($gamefle)
										For $n = 1 To $games[0]
											$title = $games[$n]
											If StringInStr($title, "®") > 0 Or StringInStr($title, "™") > 0 _
												Or StringInStr($title, "’") > 0 Then
												$game = StringReplace($title, "®", "")
												$game = StringReplace($game, "™", "")
												$game = StringReplace($game, "’", "'")
												;$game = StringReplace($game, Chr(130), "'")
												;$game = StringReplace($game, Chr(145), "'")
												;$game = StringReplace($game, Chr(146), "'")
												;$game = StringReplace($game, Chr(180), "'")
												;$game = StringStripWS($game, 7)
												If StringInStr($read, "[" & $game & "]") > 0 Then
													$ans = MsgBox(262211, "Removal Query", _
														"The following duplicate was found." & @LF & @LF & _
														$game & @LF & @LF & _
														"It also exists as the following." & @LF & @LF & _
														$title & @LF & @LF & _
														"YES = Remove the duplicate." & @LF & _
														"NO = Skip to next duplicate." & @LF & _
														"CANCEL = Abort any removals.", 0, $WishlistGUI)
													If $ans = 6 Then
														$reload = 1
														IniDelete($gamefle, $game)
														$titles = $titles - 1
														$removed = $removed + 1
													ElseIf $ans = 2 Then
														ExitLoop
													EndIf
												EndIf
											ElseIf StringIsASCII($title) = 0 Then
												;$title = StringReplace($title, "’", "'")
												;$title = StringReplace($title, Chr(130), "'")
												;$title = StringReplace($title, Chr(145), "'")
												;$title = StringReplace($title, Chr(146), "'")
												;$title = StringReplace($title, Chr(180), "'")
												;MsgBox(262192, "Character Detection Result", "The following game title has at least one uncommon character!" _
												;	& @LF & @LF & $title, 0, $WishlistGUI)
											EndIf
										Next
										MsgBox(262192, "End Result", $removed & " entries were removed from database." & @LF _
											& @LF & "Database (" & $titles & ")." _
											& @LF & "Wishlist (" & $found & ").", 0, $WishlistGUI)
									EndIf
								EndIf
							EndIf
							If $reload = 1 Then
								GUICtrlSetData($Input_title, "Please Wait - Reloading List")
								GUICtrlSetBkColor($Input_title, 0xFF0000)
								If $slick = 1 Then
									GUISetState($WishlistGUI, @SW_DISABLE)
									_GUICtrlListView_BeginUpdate($Listview_items)
								EndIf
								_GUICtrlListView_DeleteAllItems($Listview_items)
								LoadTheList()
								If $slick = 1 Then
									_GUICtrlListView_EndUpdate($Listview_items)
									GUISetState($WishlistGUI, @SW_ENABLE)
								EndIf
							EndIf
						EndIf
					EndIf
					GUICtrlSetData($Input_title, "")
					GUICtrlSetBkColor($Input_title, Default)
					GUICtrlSetState($Checkbox_next, $GUI_ENABLE)
					GUICtrlSetState($Checkbox_all, $GUI_ENABLE)
					DisableEnableControls($GUI_ENABLE)
				EndIf
			ElseIf $ans = 7 Then
				; This should be a once off fix, to correct or add missing prices.
				DisableEnableControls($GUI_DISABLE)
				GUICtrlSetState($Checkbox_next, $GUI_DISABLE)
				GUICtrlSetState($Checkbox_all, $GUI_DISABLE)
				While 1
					$ans = MsgBox(262209, "Correction Query", _
						"Normally the following will not be needed." & @LF & _
						"I needed it when updating 'Games.ini' from" & @LF & _
						"my 'GetGOG Wishlist' program for use with" & @LF & _
						"this 'GOGger Wishlist' adapted one." & @LF & @LF & _
						"This option can correct (fix) missing 'Prior'," &  @LF & _
						"'Start', 'Low' and 'High' column prices." & @LF & @LF & _
						"If 'Last' is missing, replace the entire entry." & @LF & @LF & _
						"It can also fix the value in the Price column" &  @LF & _
						"where only a single decimal is displaying." & @LF & _
						"NOTE - Not recommended for use after a" & @LF & _
						"column sort that results in single decimals." & @LF & _
						"That result is an inbuilt Listview limitation," & @LF & _
						"and may not reflect the true stored value." & @LF & @LF & _
						"The processing starts at the selected entry," & @LF & _
						"and always stops after any correction. The" & @LF & _
						"type(s) of correction are shown in the Title" & @LF & _
						"input field above the games wishlist." & @LF & @LF & _
						"Enable the 'Stop' checkbox to cancel fixing." & @LF & @LF & _
						"OK = Contine with corrections." & @LF & _
						"CANCEL = Abort corrections.", 0, $WishlistGUI)
					If $ans = 1 Then
						If $e < 0 Then
							$v = 0
						Else
							$v = $e
						EndIf
						$nums = _GUICtrlListView_GetItemCount($Listview_items)
						For $e = $v to $nums - 1
							_GUICtrlListView_EnsureVisible($Listview_items, $e, False)
							_GUICtrlListView_SetItemSelected($Listview_items, $e, True, True)
							;_GUICtrlListView_ClickItem($Listview_items, $e, "right", False, 1, 1)
							$title = _GUICtrlListView_GetItemText($Listview_items, $e, 1)
							;GUICtrlSetData($Input_title, $title)
							$start = _GUICtrlListView_GetItemText($Listview_items, $e, 2)
							$low = _GUICtrlListView_GetItemText($Listview_items, $e, 3)
							$high = _GUICtrlListView_GetItemText($Listview_items, $e, 4)
							$prior = _GUICtrlListView_GetItemText($Listview_items, $e, 5)
							$last = _GUICtrlListView_GetItemText($Listview_items, $e, 6)
							$current = $last
							$digits = StringSplit($current, ".", 1)
							If $digits[0] = 2 Then
								$dollars = $digits[1]
								If $dollars = "" Then $current = "0" & $current
								$cents = $digits[2]
								If StringLen($cents) = 1 Then
									$current = $current & "0"
								EndIf
							Else
								$current = $current & ".00"
							EndIf
							$fixed = 0
							If $current <> $last And $last <> 0 Then
								; Fix price that only has one decimal in the Price column.
								$fixed = 1
								$last = $current
								IniWrite($gamefle, $title, "last", $last)
								_GUICtrlListView_SetItemText($Listview_items, $e, $last, 6)
							EndIf
							If $prior = "" Then
								; Fix missing prior price condition in the Prior column.
								$fixed = $fixed + 2
								$prior = $last
								IniWrite($gamefle, $title, "prior", $prior)
								_GUICtrlListView_SetItemText($Listview_items, $e, $prior, 5)
							EndIf
							If $start = "" Or $start = "na" Then
								; Fix missing start price condition in the Start column.
								$fixed = $fixed + 4
								$start = $prior
								IniWrite($gamefle, $title, "start", $start)
								_GUICtrlListView_SetItemText($Listview_items, $e, $start, 2)
							EndIf
							If $low = "" Then
								; Fix missing low price condition in the Low column.
								$fixed = $fixed + 12
								$first = Number($prior)
								$second = Number($last)
								If $first = $second Then
									$low = $prior
								ElseIf $first < $second Then
									$low = $prior
								ElseIf $first > $second Then
									$low = $last
								EndIf
								IniWrite($gamefle, $title, "lowest", $low)
								_GUICtrlListView_SetItemText($Listview_items, $e, $low, 3)
							EndIf
							If $high = "" Then
								; Fix missing high price condition in the Low column.
								$fixed = $fixed + 20
								$first = Number($prior)
								$second = Number($last)
								If $first = $second Then
									$high = $prior
								ElseIf $first < $second Then
									$high = $last
								ElseIf $first > $second Then
									$high = $prior
								EndIf
								IniWrite($gamefle, $title, "highest", $high)
								_GUICtrlListView_SetItemText($Listview_items, $e, $high, 4)
							EndIf
							If $fixed > 0 Then
								_GUICtrlListView_ClickItem($Listview_items, $e, "right", False, 1, 1)
								If $fixed = 1 Then
									; 1 (Last)
									GUICtrlSetData($Input_title, "Last = " & $last)
								ElseIf $fixed = 2 Then
									; 2 (Prior)
									GUICtrlSetData($Input_title, "Prior = " & $prior)
								ElseIf $fixed = 3 Then
									; 1 + 2 (Last & Prior)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Prior = " & $prior)
								ElseIf $fixed = 4 Then
									; 4 (Start)
									GUICtrlSetData($Input_title, "Start = " & $start)
								ElseIf $fixed = 5 Then
									; 1 + 4 (Last & Start)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Start = " & $start)
								ElseIf $fixed = 6 Then
									; 2 + 4 (Prior & Start)
									GUICtrlSetData($Input_title, "Prior = " & $prior & ", Start = " & $start)
								ElseIf $fixed = 7 Then
									; 1 + 2 + 4 (Last & Prior & Start)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Prior = " & $prior & ", Start = " & $start)
								ElseIf $fixed = 12 Then
									; 12 (Low)
									GUICtrlSetData($Input_title, "Low = " & $low)
								ElseIf $fixed = 13 Then
									; 1 + 12 (Last & Low)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Low = " & $low)
								ElseIf $fixed = 14 Then
									; 2 + 12 (Prior & Low)
									GUICtrlSetData($Input_title, "Prior = " & $prior & ", Low = " & $low)
								ElseIf $fixed = 15 Then
									; 1 + 2 + 12 (Last & Prior & Low)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Prior = " & $prior & ", Low = " & $low)
								ElseIf $fixed = 16 Then
									; 4 + 12 (Start & Low)
									GUICtrlSetData($Input_title, "Start = " & $start & ", Low = " & $low)
								ElseIf $fixed = 17 Then
									; 2 + 4 + 12 (Prior & Start & Low)
									GUICtrlSetData($Input_title, "Prior = " & $prior & ", Start = " & $start & ", Low = " & $low)
								ElseIf $fixed = 19 Then
									; 1 + 2 + 4 + 12 (Last & Prior & Start & Low)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Prior = " & $prior & ", Start = " & $start & ", Low = " & $low)
								ElseIf $fixed = 20 Then
									; 20 (High)
									GUICtrlSetData($Input_title, "High = " & $high)
								ElseIf $fixed = 21 Then
									; 1 + 20 (Last & High)
									GUICtrlSetData($Input_title, "Last = " & $last & ", High = " & $high)
								ElseIf $fixed = 22 Then
									; 2 + 20 (Prior & High)
									GUICtrlSetData($Input_title, "Prior = " & $prior & ", High = " & $high)
								ElseIf $fixed = 23 Then
									; 1 + 2 + 20 (Last & Prior & High)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Prior = " & $prior & ", High = " & $high)
								ElseIf $fixed = 24 Then
									; 4 + 20 (Start & High)
									GUICtrlSetData($Input_title, "Start = " & $start & ", High = " & $high)
								ElseIf $fixed = 26 Then
									; 2 + 4 + 20 (Prior & Start & High)
									GUICtrlSetData($Input_title, "Prior = " & $prior & ", Start = " & $start & ", High = " & $high)
								ElseIf $fixed = 27 Then
									; 1 + 2 + 4 + 20 (Last & Prior & Start & High)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Prior = " & $prior & ", Start = " & $start & ", High = " & $high)
								ElseIf $fixed = 32 Then
									; 12 + 20 (Low & High)
									GUICtrlSetData($Input_title, "Low = " & $low & ", High = " & $high)
								ElseIf $fixed = 33 Then
									; 1 + 12 + 20 (Last & Low & High)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Low = " & $low & ", High = " & $high)
								ElseIf $fixed = 34 Then
									; 2 + 12 + 20 (Prior & Low & High)
									GUICtrlSetData($Input_title, "Prior = " & $prior & ", Low = " & $low & ", High = " & $high)
								ElseIf $fixed = 35 Then
									; 1 + 2 + 12 + 20 (Last & Prior & Low & High)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Prior = " & $prior & ", Low = " & $low & ", High = " & $high)
								ElseIf $fixed = 39 Then
									; 1 + 2 + 4 + 12 + 20 (Last & Prior & Start & Low & High)
									GUICtrlSetData($Input_title, "Last = " & $last & ", Prior = " & $prior & ", Start = " & $start & ", Low = " & $low & ", High = " & $high)
								EndIf
								ExitLoop
							EndIf
							If $e = ($nums - 1) Then ExitLoop 2
							;If $e = 10 Then ExitLoop
							If GUICtrlRead($Checkbox_stop) = $GUI_CHECKED Then
								_GUICtrlListView_ClickItem($Listview_items, $e, "right", False, 1, 1)
								GUICtrlSetData($Input_title, $title)
								GUICtrlSetData($Input_price, $currency & $current)
								ExitLoop 2
							EndIf
							Sleep(200)
						Next
					ElseIf $ans = 2 Then
						ExitLoop
					EndIf
				WEnd
				GUICtrlSetState($Checkbox_next, $GUI_ENABLE)
				GUICtrlSetState($Checkbox_all, $GUI_ENABLE)
				DisableEnableControls($GUI_ENABLE)
			EndIf
		EndIf
	Case $msg = $Button_remove
		; Remove a game from the list
		If $title <> "" And $e > -1 Then
			$removed = ""
			$gameID = IniRead($gamefle, $title, "id", "")
			$ans = MsgBox(262209, "Removal", _
				"Title = " & $title & @LF & _
				"Game ID = " & $gameID & @LF & @LF & _
				"OK = Remove selected game." & @LF & _
				"CANCEL = Abort Removal.", 0, $WishlistGUI)
			If $ans = 1 Then
				IniDelete($gamefle, $title)
				_GUICtrlListView_DeleteItem($Listview_items, $e)
				GUICtrlSetData($Input_title, "")
				GUICtrlSetData($Input_price, "")
				GUICtrlSetData($Input_id, "")
				$lne = $lne - 1
				GUICtrlSetData($Group_list, "List Of Games On Wishlist  (" & $lne & ")")
				$bigid = $lowid + $lne + 1
				$removed = 1
			EndIf
			If $removed = 1 Then
				DisableEnableControls($GUI_DISABLE)
				GUICtrlSetData($Input_title, "Please Wait - Reloading List")
				GUICtrlSetBkColor($Input_title, 0xFF0000)
				If $slick = 1 Then
					GUISetState($WishlistGUI, @SW_DISABLE)
					_GUICtrlListView_BeginUpdate($Listview_items)
				EndIf
				_GUICtrlListView_DeleteAllItems($Listview_items)
				LoadTheList()
				If $slick = 1 Then
					_GUICtrlListView_EndUpdate($Listview_items)
					GUISetState($WishlistGUI, @SW_ENABLE)
				EndIf
				GUICtrlSetData($Input_title, "")
				GUICtrlSetBkColor($Input_title, Default)
				DisableEnableControls($GUI_ENABLE)
			EndIf
		Else
			MsgBox(262192, "Selection Error", "No game title has been selected!", 0, $WishlistGUI)
		EndIf
		GUICtrlSetState($Label_time, $GUI_HIDE)
	Case $msg = $Button_ontop
		; Toggle the On Top setting
		If GUICtrlRead($Button_ontop) = $GUI_CHECKED Then
			$ontop = 1
			WinSetOnTop($WishlistGUI, "", 1)
		Else
			$ontop = 4
			WinSetOnTop($WishlistGUI, "", 0)
		EndIf
		IniWrite($inifle, "Program Window", "on_top", $ontop)
	Case $msg = $Button_info
		; Information about the program
		$ans = MsgBox(262209, "Program Information", _
			"I created this program due to limitations of online GOG Wishlist." & @LF & @LF & _
			"The first 7 columns can be sorted ascendingly by clicking on the" & @LF & _
			"column header (title bar) for each. Sometimes 1 decimal results." & @LF & @LF & _
			"ADD GAME button has two methods (see details when clicked)." & @LF & @LF & _
			"WEB PAGE button connects to online web page, for the selected" & @LF & _
			"game, and loads it into your browser. The WEB PAGE button can" & @LF & _
			"also be changed to a COPY URL button, or a goto WISHLIST one" & @LF & _
			"by cycling through three states of the checkbox on its right. The" & @LF & _
			"three states also change the FIND button name and process." & @LF & @LF & _
			"FIND title button process requires text in the field to its left, or if" & @LF & _
			"renamed to PRICE copies price, or if to TITLE copies the title." & @LF & @LF & _
			"CHECK PRICE button either queries the current price of a single" & @LF & _
			"selected entry, or with ALL selected, queries the price for all list" & @LF & _
			"entries, starting at the selected one. Deselecting stops a query." & @LF & @LF & _
			"REMOVE button removes a single selected entry from the list." & @LF & @LF & _
			"UPDATE button crosschecks Wishlist entries against purchases" & @LF & _
			"listed in the 'Games.ini' file of my GOGcli GUI program.  If any" & @LF & _
			"matches are found, they are then removed from the Wishlist." & @LF & @LF & _
			"UPDATE process can be stopped between checks, by enabling" & @LF & _
			"the 'Stop' checkbox." & @LF & @LF & _
			"A selected game can have its URL updated, using that button." & @LF & @LF & _
			"Click OK to see more information.", 0, $WishlistGUI)
		If $ans = 1 Then
			$ans = MsgBox(262209, "Program Information (cont.)", _
				"Country Code or Username changes will be saved (updated)" & @LF & _
				"when the program exits. Price checks rely on country code." & @LF & @LF & _
				"Using the WISHLIST button requires the correct GOG account" & @LF & _
				"name. This can be changed during that process." & @LF & @LF & _
				"Lines are colored RED or GREEN according to query results, or" & @LF & _
				"ORANGE if less the a '.20' change. RED is an increase in price," & @LF & _
				"GREEN is a decrease. Standard line color is Pale Green or Pale" & @LF &  _
				"Pink on loading, except where an entry displays a '0' price, in" & @LF &  _
				"which case it is colored Light Blue (same for ADD or CHECK)." & @LF & _
				"At program start, if the Price is lowest and less than Start then" & @LF & _
				"that line is colored Yellow instead." & @LF & @LF & _
				"This program is a companion to my IonGoG Wishlist program." & @LF & _
				"This program is an adaption of my GetGoG Wishlist program." & @LF & @LF & _
				"© GOGger Wishlist - created by Timboli (September 2021)." & @LF & _
				$version & @LF & @LF & _
				"Click OK to open the program folder.", 0, $WishlistGUI)
			If $ans = 1 Then ShellExecute(@ScriptDir)
		EndIf
		GUICtrlSetState($Label_time, $GUI_HIDE)
	Case $msg = $Button_find
		; Find the specified text
		$buttxt = GUICtrlRead($Button_find)
		If $buttxt = "FIND" Then
			$text = GUICtrlRead($Input_title)
			If $text <> "" Then
				SplashTextOn("", "Please Wait!", 200, 120, -1, -1, 33)
				$e = _GUICtrlListView_GetSelectedIndices($Listview_items, True)
				If $e[0] = 1 Then
					$e = $e[1]
				Else
					$e = -1
				EndIf
				_GUICtrlListView_SetItemSelected($Listview_items, $e, True, True)
				Sleep(1000)
				$e = _GUICtrlListView_FindInText($Listview_items, $text, $e, True, False)
				SplashOff()
				If $e > -1 Then
					_GUICtrlListView_EnsureVisible($Listview_items, $e, False)
					_GUICtrlListView_SetItemSelected($Listview_items, $e, True, True)
					_GUICtrlListView_ClickItem($Listview_items, $e, "right", False, 1, 1)
					;_GUICtrlListView_SetHotItem($Listview_items, $e)Draugen
					;_GUICtrlListView_SetItemDropHilited($Listview_items, $e, True)
					;_GUICtrlListView_SetItemDropHilited($Listview_items, $e, False)
					;_GUICtrlListView_SetItemFocused($Listview_items, $e, True)
					;_GUICtrlListView_SetItemState($Listview_items, $e, $LVIS_FOCUSED, $LVIS_FOCUSED)
					;_GUICtrlListView_SetItemCut($Listview_items, $e, True)
				Else
					MsgBox(262192, "Find Error", "Search text not found, or already selected!", 0, $WishlistGUI)
				EndIf
			Else
				MsgBox(262192, "Find Error", "No search text specified in the title field at left!", 0, $WishlistGUI)
			EndIf
		ElseIf $buttxt = "PRICE" Then
			$price = GUICtrlRead($Input_price)
			ClipPut($price)
		ElseIf $buttxt = "TITLE" Then
			$title = GUICtrlRead($Input_title)
			ClipPut($title)
		EndIf
		GUICtrlSetState($Label_time, $GUI_HIDE)
	Case $msg = $Button_detail
		; Detail for selected game
		$title = GUICtrlRead($Input_title)
		If $title <> "" Then
			$gameID = IniRead($gamefle, $title, "id", "")
			$link = IniRead($gamefle, $title, "url", "")
			$URL = "https://www.gog.com" & $link
			$added = IniRead($gamefle, $title, "added", "")
			$last = IniRead($gamefle, $title, "last", "")
			$current = $currency & $last
			$checked = IniRead($gamefle, $title, "checked", "")
			$ans = MsgBox(262209, "Game Detail (" & $e & ")", _
				"Title = " & $title & @LF & _
				"Game ID = " & $gameID & @LF & _
				"URL = " & $URL & @LF & _
				"Added = " & $added & @LF & _
				"Current Price = " & $current & @LF & _
				"Last Checked = " & $checked & @LF & @LF & _
				"Click OK to open the Log file.", 0, $WishlistGUI)
			If $ans = 1 Then
				If FileExists($logfle) Then ShellExecute($logfle)
			EndIf
		Else
			MsgBox(262192, "Detail Error", "No game title has been selected!", 0, $WishlistGUI)
		EndIf
		GUICtrlSetState($Label_time, $GUI_HIDE)
	Case $msg = $Button_check
		; Check price of one selected entry or ALL entries from selected.
		DisableEnableControls($GUI_DISABLE)
		GUICtrlSetState($Label_time, $GUI_SHOW)
		$status = "Started at " & _NowTime()
		GUICtrlSetData($Label_time, $status)
		;
		If GUICtrlRead($Checkbox_all) = $GUI_CHECKED Then
			; Clear previous record of changes.
			_ReplaceStringInFile($gamefle, "changed=less", "changed=")
			_ReplaceStringInFile($gamefle, "changed=more", "changed=")
			_ReplaceStringInFile($gamefle, "changed=subtle", "changed=")
			;_ReplaceStringInFile($gamefle, "changed=fail", "changed=")
		EndIf
		;
		$nums = _GUICtrlListView_GetItemCount($Listview_items)
		While 1
			If $title <> "" And $e > -1 Then
				$link = IniRead($gamefle, $title, "url", "")
				If $link <> "" Then
					GUICtrlSetData($Input_title, "Please Wait - Checking Selected")
					GUICtrlSetBkColor($Input_title, 0xFF0000)
					$gameID = IniRead($gamefle, $title, "id", "")
					GUICtrlSetData($Input_id, $gameID)
					If $gameID = "" Then
						$URL = "https://www.gog.com" & $link
						If $date <> "" Then
							If _DateDiff('s', $date, _NowCalc()) > 30 Then $date = ""
						EndIf
						If $date = "" Then
							;GUICtrlSetData($Input_id, "Ping")
							$ping = Ping("gog.com", 5000)
						EndIf
						If $ping > 0 Then
							If $date = "" Then $date = _NowCalc()
							$html = _INetGetSource($URL, True)
							If @error = 0 Then
								If $html = "" Then
									MsgBox(262192, "Download Error", "The web page html wasn't returned!", 3, $WishlistGUI)
								EndIf
							Else
								MsgBox(262192, "Page Error", "The web page doesn't appear to exist!", 3, $WishlistGUI)
								$html = ""
							EndIf
							If $html <> "" Then
								$gameID = StringSplit($html, ' card-product="', 1)
								If $gameID[0] = 2 Then
									$gameID = $gameID[2]
									$gameID = StringSplit($gameID, '"', 1)
									$gameID = $gameID[1]
									GUICtrlSetData($Input_title, "Please Wait - ID Found")
									GUICtrlSetBkColor($Input_title, $COLOR_LIME)
								Else
									$gameID = StringSplit($html, '"ProductCardCtrl"', 1)
									If $gameID[0] = 2 Then
										$gameID = $gameID[2]
										$gameID = StringSplit($gameID, 'gog-product="', 1)
										If $gameID[0] > 1 Then
											$gameID = $gameID[2]
											$gameID = StringSplit($gameID, '"', 1)
											$gameID = $gameID[1]
											GUICtrlSetData($Input_title, "Please Wait - ID Found")
											GUICtrlSetBkColor($Input_title, $COLOR_LIME)
										Else
											$gameID = ""
										EndIf
									Else
										$gameID = ""
									EndIf
									If $gameID = "" Then
										_FileCreate($webfle)
										FileWrite($webfle, $html)
										MsgBox(262192, "ID Error", "The Game ID could not be detected!" & @LF & "Possibly web page no longer exists.", 5, $WishlistGUI)
									EndIf
								EndIf
								IniWrite($gamefle, $title, "id", $gameID)
								GUICtrlSetData($Input_id, $gameID)
							EndIf
						Else
							MsgBox(262192, "Ping Error", "Change the server address or increase timeout!", 0, $WishlistGUI)
							$html = ""
						EndIf
					EndIf
					If $gameID <> "" Then
						GUICtrlSetData($Input_title, "Please Wait - Checking Price")
						GUICtrlSetBkColor($Input_title, 0xFF0000)
						$cc = GUICtrlRead($Input_cc)
						$query = "https://api.gog.com/products/" & $gameID & "/prices?countryCode=" & StringLeft($cc, 2)
						$gethtml = _INetGetSource($query)
						If $gethtml = "" Then
							$check = ""
						Else
							$check = StringSplit($gethtml, '{"code":"' & $cc & '"}', 1)
							If $check[0] = 2 Then
								$check = $check[2]
								$check = StringSplit($check, '"finalPrice":"', 1)
								If $check[0] > 1 Then
									$checked = _Now()
									IniWrite($gamefle, $title, "checked", $checked)
									$check = $check[2]
									$check = StringSplit($check, ' ' & $cc & '"', 1)
									$check = $check[1]
									$check = $check / 100
									If StringInStr($check, ".") > 0 Then
										$check = StringSplit($check, '.', 1)
										If StringLen($check[2]) = 1 Then
											$check = $check[1] & "." & $check[2] & "0"
										Else
											$check = $check[1] & "." & $check[2]
										EndIf
									Else
										$check = $check & ".00"
									EndIf
									GUICtrlSetData($Input_title, "Please Wait - Price Found")
									GUICtrlSetBkColor($Input_title, $COLOR_LIME)
									GUICtrlSetData($Input_price, $currency & $check)
									$price = $check
									$start = IniRead($gamefle, $title, "start", "")
									$low = IniRead($gamefle, $title, "lowest", "")
									$high = IniRead($gamefle, $title, "highest", "")
									$prior = IniRead($gamefle, $title, "prior", "")
									$last = IniRead($gamefle, $title, "last", "")
									If $last = "" Or Number($price) < Number($last) Then
										; New or Lower
										$price = CheckForTwoDecimalPlaces($price)
										If $last = "" Then
											; New entry
											; Light Blue
											$color = 0x80FFFF
										Else
											; Cheaper
											; Green
											$color = 0x60E000
										EndIf
										$prior = $last
										IniWrite($gamefle, $title, "prior", $prior)
										_GUICtrlListView_SetItemText($Listview_items, $e, $last, 5)
										$last = $price
										IniWrite($gamefle, $title, "last", $last)
										_GUICtrlListView_SetItemText($Listview_items, $e, $last, 6)
										; Check to see if lowest price
										If Number($low) > Number($last) Then
											$low = $last
											IniWrite($gamefle, $title, "lowest", $low)
											_GUICtrlListView_SetItemText($Listview_items, $e, $low, 3)
										EndIf
										$changed = "less"
										IniWrite($gamefle, $title, "changed", $changed)
										_FileWriteLog($logfle, $title & " - " & $price & " (lower)")
									ElseIf Number($price) > Number($last) Then
										; Dearer or Higher
										If ($price - $last) > Number(.20) Then
											; Red
											$color = 0xF02000
											$changed = "more"
										Else
											; Orange
											$color = 0xFF8000
											$changed = "subtle"
										EndIf
										$prior = $last
										IniWrite($gamefle, $title, "prior", $prior)
										_GUICtrlListView_SetItemText($Listview_items, $e, $last, 5)
										$price = CheckForTwoDecimalPlaces($price)
										$last = $price
										IniWrite($gamefle, $title, "last", $last)
										_GUICtrlListView_SetItemText($Listview_items, $e, $last, 6)
										; Check to see if highest price
										If Number($high) < Number($last) Then
											$high = $last
											IniWrite($gamefle, $title, "highest", $high)
											_GUICtrlListView_SetItemText($Listview_items, $e, $high, 4)
										EndIf
										IniWrite($gamefle, $title, "changed", $changed)
										_FileWriteLog($logfle, $title & " - " & $price & " (higher)")
									Else
										; No Change or Same Price as last
										;$low = Number(IniRead($gamefle, $title, "lowest", ""))
										;If $low = "" Then
										If $start = "na" Then
											; Pink
											$color = 0xFF80FF
										ElseIf $price = "0.00" Then
											; Light Blue
											$color = 0x80FFFF
										Else
											If IsInt(($e + 1) / 2) <> 1 Then
												; Pale Pink
												$color = 0xF0D0F0
											Else
												; Pale Green
												$color = 0xC0F0C0
											EndIf
										EndIf
										;Else
										;	; Discount has been recorded at least once.
										;	; Pink
										;	$color = 0xFF80FF
										;EndIf
										;$price = CheckForTwoDecimalPlaces($price)
										;IniWrite($gamefle, $title, "higher", "")
									EndIf
									GUICtrlSetBkColor($lowid + $e + 1, $color)
								Else
									$check = ""
								EndIf
							Else
								$check = ""
							EndIf
						EndIf
						If $check = "" Then
							If $gethtml <> "" Then
								_FileCreate($webfle)
								FileWrite($webfle, $gethtml)
								$gethtml = @LF & @LF & $gethtml
							EndIf
							; Pink
							$color = 0xFF80FF
							GUICtrlSetBkColor($lowid + $e + 1, $color)
							_FileWriteLog($logfle, $title & " - price query failed.")
							$ping = Ping("gog.com", 5000)
							If $ping > 0 Then
								$wait = 6
								$failure = "Query failed for selected entry!"
								$close = @LF & @LF & "(autoclose in 6 seconds)"
							Else
								$wait = 0
								$failure = "Web connection (or ping) appears to have failed!"
								$close = ""
							EndIf
							;$changed = "fail"
							;IniWrite($gamefle, $title, "changed", $changed)
							MsgBox(262192, "Check Result", $failure & $close & $gethtml, $wait, $WishlistGUI)
						EndIf
					Else
						MsgBox(262192, "Query Error", "No Game ID found!", 0, $WishlistGUI)
					EndIf
					GUICtrlSetData($Input_title, $title)
					GUICtrlSetBkColor($Input_title, Default)
					;
					If $e < ($nums - 1) Then
						$next = GUICtrlRead($Checkbox_next)
						$all = GUICtrlRead($Checkbox_all)
						If $next = $GUI_CHECKED Or $all = $GUI_CHECKED Then
							Sleep(500)
							$e = $e + 1
							_GUICtrlListView_EnsureVisible($Listview_items, $e, False)
							_GUICtrlListView_SetItemSelected($Listview_items, $e, True, True)
							_GUICtrlListView_ClickItem($Listview_items, $e, "right", False, 1, 1)
							$title = _GUICtrlListView_GetItemText($Listview_items, $e, 1)
						EndIf
					Else
						ExitLoop
					EndIf
				Else
					MsgBox(262192, "Link Error", "No URL found for selected game!", 0, $WishlistGUI)
				EndIf
			Else
				MsgBox(262192, "Selection Error", "Entry is not selected correctly!", 0, $WishlistGUI)
			EndIf
			If $all = $GUI_UNCHECKED Then ExitLoop
		WEnd
		$status = $status & " and Finished at " & _NowTime()
		GUICtrlSetData($Label_time, $status)
		$show = 1
		_GUICtrlListView_ClickItem($Listview_items, $e, "left", False, 1, 1)
		DisableEnableControls($GUI_ENABLE)
	Case $msg = $Button_add
		; Add a game to the wishlist
		; NOTE - Two choices for ADD - (1) Single via URL, or (2) Multiple via a saved Wishlist page.
		; Don't forget ADD date. $added = IniRead($gamefle, $title, "added", "")
		$ans = MsgBox(262179, "ADD To The Wishlist - " & $user, _
			"This program involves manual ADD or some semblance" & @LF & _
			"of automated ADD, via saved wishlist web page(s). You" & @LF & _
			"will need to have pre-saved the web page(s) before you" & @LF & _
			"use that Multiple ADD option here." & @LF & @LF & _
			"YES = Individual ADD via game web page URL." & @LF & _
			"NO = Multiple ADD via saved wishlist web page(s)." & @LF & _
			"CANCEL = Another choice using the web." & @LF & @LF & _
			"NOTE - 'Stop' checkbox can be used with Multiple ADD.", 0, $WishlistGUI)
		If $ans = 6 Then
			; Individual ADD via game web page URL.
			DisableEnableControls($GUI_DISABLE)
			GUICtrlSetState($Checkbox_next, $GUI_DISABLE)
			GUICtrlSetState($Checkbox_all, $GUI_DISABLE)
			GUICtrlSetState($Checkbox_stop, $GUI_DISABLE)
			While 1
				$link = ClipGet()
				If StringLeft($link, 4) <> "http" Then $link = ""
				$URL = InputBox("ADD A Game", "Please enter the game web page URL.", $link, "", 400, 130, Default, Default, 0, $WishlistGUI)
				If @error = 0 And StringLeft($URL, 4) = "http" Then
					GUICtrlSetData($Input_title, "Please Wait - Downloading Web Page")
					GUICtrlSetBkColor($Input_title, $COLOR_LIME)
					$ping = Ping("gog.com", 5000)
					If $ping > 0 Then
						$html = _INetGetSource($URL, True)
						If @error = 0 Then
							If $html = "" Then
								MsgBox(262192, "Download Error", "The web page html wasn't returned!", 3, $WishlistGUI)
							EndIf
						Else
							MsgBox(262192, "Page Error", "The web page doesn't appear to exist!", 3, $WishlistGUI)
							$html = ""
						EndIf
						If $html <> "" Then
							$gameID = StringSplit($html, ' card-product="', 1)
							If $gameID[0] = 2 Then
								$gameID = $gameID[2]
								$gameID = StringSplit($gameID, '"', 1)
								$gameID = $gameID[1]
								GUICtrlSetData($Input_title, "Please Wait - ID Found")
								GUICtrlSetBkColor($Input_title, $COLOR_LIME)
							Else
								$gameID = StringSplit($html, '"ProductCardCtrl"', 1)
								If $gameID[0] = 2 Then
									$gameID = $gameID[2]
									$gameID = StringSplit($gameID, 'gog-product="', 1)
									If $gameID[0] > 1 Then
										$gameID = $gameID[2]
										$gameID = StringSplit($gameID, '"', 1)
										$gameID = $gameID[1]
										GUICtrlSetData($Input_title, "Please Wait - ID Found")
										GUICtrlSetBkColor($Input_title, $COLOR_LIME)
									Else
										$gameID = ""
									EndIf
								Else
									$gameID = ""
								EndIf
								If $gameID = "" Then
									_FileCreate($webfle)
									FileWrite($webfle, $html)
									MsgBox(262192, "ID Error", "The Game ID could not be detected!" & @LF & "Possibly web page no longer exists.", 5, $WishlistGUI)
								EndIf
							EndIf
							If $gameID <> "" Then
								$game = StringSplit($html, "<title>", 1)
								If $game[0] > 1 Then
									$game = $game[2]
									$game = StringSplit($game, "</title>", 1)
									$game = $game[1]
									$game = StringReplace($game, "on GOG.com", "")
									$title = StringStripWS($game, 7)
									If $title <> "" Then
										If IniRead($gamefle, $title, "last", "") = "" Then
											GUICtrlSetData($Input_price, "")
											IniWrite($gamefle, $title, "id", $gameID)
											GUICtrlSetData($Input_id, $gameID)
											IniWrite($gamefle, $title, "added", _Now())
											$link = StringSplit($URL, "//www.gog.com", 1)
											If $link[0] > 1 Then
												$link = $link[2]
											Else
												$link = ""
											EndIf
											IniWrite($gamefle, $title, "url", $link)
											GUICtrlSetData($Input_title, "Please Wait - Checking Price")
											GUICtrlSetBkColor($Input_title, 0xFF0000)
											$cc = GUICtrlRead($Input_cc)
											$query = "https://api.gog.com/products/" & $gameID & "/prices?countryCode=" & StringLeft($cc, 2)
											$gethtml = _INetGetSource($query)
											If $gethtml = "" Then
												$check = ""
											Else
												$check = StringSplit($gethtml, '{"code":"' & $cc & '"}', 1)
												If $check[0] = 2 Then
													$check = $check[2]
													$check = StringSplit($check, '"finalPrice":"', 1)
													If $check[0] > 1 Then
														$checked = _Now()
														IniWrite($gamefle, $title, "checked", $checked)
														$check = $check[2]
														$check = StringSplit($check, ' ' & $cc & '"', 1)
														$check = $check[1]
														$check = $check / 100
														If StringInStr($check, ".") > 0 Then
															$check = StringSplit($check, '.', 1)
															If StringLen($check[2]) = 1 Then
																$check = $check[1] & "." & $check[2] & "0"
															Else
																$check = $check[1] & "." & $check[2]
															EndIf
														Else
															$check = $check & ".00"
														EndIf
														GUICtrlSetData($Input_title, "Please Wait - Price Found")
														GUICtrlSetBkColor($Input_title, $COLOR_LIME)
														GUICtrlSetData($Input_price, $currency & $check)
														$price = $check
														$start = $price
														$low = $price
														$high = $price
														$prior = $price
														$last = $price
													Else
														$check = ""
													EndIf
												Else
													$check = ""
												EndIf
											EndIf
											If $check = "" Then
												$start = ""
												$low = ""
												$high = ""
												$prior = ""
												$last = ""
												If $gethtml <> "" Then
													_FileCreate($webfle)
													FileWrite($webfle, $gethtml)
													$gethtml = @LF & @LF & $gethtml
												EndIf
												MsgBox(262192, "Check Result", "Price query failed for selected entry!" & $gethtml, 0, $WishlistGUI)
											EndIf
											IniWrite($gamefle, $title, "start", $start)
											IniWrite($gamefle, $title, "lowest", $low)
											IniWrite($gamefle, $title, "highest", $high)
											IniWrite($gamefle, $title, "prior", $prior)
											IniWrite($gamefle, $title, "last", $last)
											$nums = _GUICtrlListView_GetItemCount($Listview_items)
											$lne = $nums + 1
											GUICtrlCreateListViewItem($lne & "|" & $title & "|" & $start & "|" & $low & "|" & $high & "|" & $prior & "|" & $last & "|" & $link, $Listview_items)
											$low = Number(IniRead($gamefle, $title, "lowest", ""))
											If $low = 0 Then
												; Light Blue
												$color = 0x80FFFF
											ElseIf IsInt($lne / 2) <> 1 Then
												; Pale Pink
												$color = 0xF0D0F0
											Else
												; Pale Green
												$color = 0xC0F0C0
											EndIf
											GUICtrlSetBkColor($lowid + $lne, $color)
											GUICtrlSetData($Group_list, "List Of Games On Wishlist  (" & $lne & ")")
											$bigid = $lowid + $lne + 1
											$e = $lne - 1
											_GUICtrlListView_EnsureVisible($Listview_items, $e, False)
											_GUICtrlListView_SetItemSelected($Listview_items, $e, True, True)
											_GUICtrlListView_ClickItem($Listview_items, $e, "right", False, 1, 1)
										Else
											MsgBox(262192, "ADD Error", "Process failed, as game already exists on the wishlist!", 0, $WishlistGUI)
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf
					Else
						MsgBox(262192, "Ping Error", "Change the server address or increase timeout!", 0, $WishlistGUI)
						$html = ""
					EndIf
					GUICtrlSetData($Input_title, "")
					GUICtrlSetBkColor($Input_title, Default)
				ElseIf $URL <> "" And StringLeft($URL, 4) <> "http" Then
					MsgBox(262192, "Link Error", "URL has not been correctly specified!", 0, $WishlistGUI)
				Else
					ExitLoop
				EndIf
			WEnd
			GUICtrlSetState($Checkbox_next, $GUI_ENABLE)
			GUICtrlSetState($Checkbox_all, $GUI_ENABLE)
			GUICtrlSetState($Checkbox_stop, $GUI_ENABLE)
			DisableEnableControls($GUI_ENABLE)
		ElseIf $ans = 7 Then
			; Multiple ADD via saved wishlist web page.
			DisableEnableControls($GUI_DISABLE)
			GUICtrlSetState($Checkbox_next, $GUI_DISABLE)
			GUICtrlSetState($Checkbox_all, $GUI_DISABLE)
			GUICtrlSetData($Input_title, "Please Wait - Selecting Web Page")
			GUICtrlSetBkColor($Input_title, $COLOR_RED)
			$auto = ""
			$nums = _GUICtrlListView_GetItemCount($Listview_items)
			$page = 0
			While 1
				$page = $page + 1
				If $auto = 1 Then
					$pos = StringInStr($webpage, "_", 0, -1)
					If $pos > 0 Then
						$webpage = StringLeft($webpage, $pos) & $page & ".html"
						If Not FileExists($webpage) Then
							$page = $page - 1
							$webpage = ""
						EndIf
					EndIf
				Else
					$webpage = IniRead($inifle, "Wishlist Web Page", "path", "")
					$pth = FileOpenDialog("Select a saved Wishlist web page file. (Page " & $page & ")", "", "Saved HTML file (*.html;*.htm)", 3, $webpage, $WishlistGUI)
					If @error <> 1 And StringMid($pth, 2, 2) = ":\" Then
						$webpage = $pth
						IniWrite($inifle, "Wishlist Web Page", "path", $webpage)
					Else
						$webpage = ""
					EndIf
				EndIf
				If $webpage = "" Then
					ExitLoop
				Else
					GUICtrlSetData($Input_title, "Please Wait - Reading Web Page")
					GUICtrlSetBkColor($Input_title, $COLOR_LIME)
					If $auto = "" Then
						If StringRight($webpage, 7) = "_1.html" Then
							$ans = MsgBox(262209, "Auto Increment Query", _
								"Are any remaining pages numbered consecutively?" & @LF & @LF & _
								"That means the next page ends in '_2.html'," &  @LF & _
								"and any following one would be '_3.html'," &  @LF & _
								"and so on." & @LF & @LF & _
								"If so, then they can be selected for you." & @LF & @LF & _
								"OK = Yes they are consecutive." & @LF & _
								"CANCEL = Not the first.", 0, $WishlistGUI)
							If $ans = 1 Then
								$auto = 1
							EndIf
						EndIf
					EndIf
					$added = 0
					$read = FileRead($webpage)
					$lines = StringSplit($read, 'product.title">', 1)
					$games = $lines[0]
					For $l = 2 to $games
						$line = $lines[$l]
						$title = $line
						$title = StringSplit($title, '</span>', 1)
						$title = $title[1]
						$title = StringReplace($title, '\u00ae', '')
						$title = StringReplace($title, '\u2122', '')
						$title = StringReplace($title, '\u2013', '-')
						$title = StringReplace($title, "\u2019", "'")
						$title = StringReplace($title, "&amp;", "&")
						$title = StringStripWS($title, 7)
						If $title <> "" Then
							If IniRead($gamefle, $title, "last", "") = "" Then
								$text = $lines[$l - 1]
								$text = StringSplit($text, ' gog-product="', 1)
								If $text[0] > 1 Then
									$text = $text[$text[0]]
									$gameID = StringSplit($text, '">', 1)
									$gameID = $gameID[1]
									$gameID = StringStripWS($gameID, 7)
									;MsgBox(262192, "$text", $text, 0, $WishlistGUI)
									$price = StringSplit($text, '"product.price.amount">', 1)
									If $price[0] > 1 Then
										$price = $price[2]
										$price = StringSplit($price, '</span>', 1)
										$price = $price[1]
										$price = StringStripWS($price, 7)
										If StringInStr($price, ".") > 0 Then
											$price = StringSplit($price, '.', 1)
											If StringLen($price[2]) = 1 Then
												$price = $price[1] & "." & $price[2] & "0"
											Else
												$price = $price[1] & "." & $price[2]
											EndIf
										Else
											$price = $price & ".00"
										EndIf
										$start = $price
										$low = $price
										$high = $price
										$prior = $price
										$last = $price
									Else
										$price = ""
										$start = ""
										$low = ""
										$high = ""
										$prior = ""
										$last = ""
									EndIf
									$link = StringSplit($text, 'ng-href="', 1)
									If $link[0] > 1 Then
										$link = $link[2]
										$link = StringSplit($link, '"', 1)
										$link = $link[1]
										$link = StringStripWS($link, 7)
									Else
										$link = ""
									EndIf
								Else
									$gameID = ""
									$price = ""
									$start = ""
									$low = ""
									$high = ""
									$prior = ""
									$last = ""
									$link = ""
								EndIf
								;MsgBox(262192, "Title ID Price Link", $title & " : " & $gameID & " : " & $price & " : " & $link, 0, $WishlistGUI)
								;If $l = 1 Then ExitLoop
								IniWrite($gamefle, $title, "id", $gameID)
								IniWrite($gamefle, $title, "added", _Now())
								IniWrite($gamefle, $title, "start", $start)
								IniWrite($gamefle, $title, "lowest", $low)
								IniWrite($gamefle, $title, "highest", $high)
								IniWrite($gamefle, $title, "prior", $prior)
								IniWrite($gamefle, $title, "last", $last)
								IniWrite($gamefle, $title, "url", $link)
								$nums = $nums + 1
								$lne = $nums
								GUICtrlCreateListViewItem($lne & "|" & $title & "|" & $start & "|" & $low & "|" & $high & "|" & $prior & "|" & $last & "|" & $link, $Listview_items)
								$low = Number(IniRead($gamefle, $title, "lowest", ""))
								If $low = 0 Then
									; Light Blue
									$color = 0x80FFFF
								ElseIf IsInt($lne / 2) <> 1 Then
									; Pale Pink
									$color = 0xF0D0F0
								Else
									; Pale Green
									$color = 0xC0F0C0
								EndIf
								GUICtrlSetBkColor($lowid + $lne, $color)
								GUICtrlSetData($Group_list, "List Of Games On Wishlist  (" & $lne & ")")
								$bigid = $lowid + $lne + 1
								$e = $lne - 1
								_GUICtrlListView_EnsureVisible($Listview_items, $e, False)
								_GUICtrlListView_SetItemSelected($Listview_items, $e, True, True)
								_GUICtrlListView_ClickItem($Listview_items, $e, "right", False, 1, 1)
								$added = $added + 1
							Else
								; Skip existing
							EndIf
							;MsgBox(262192, "Title", $title, 0, $WishlistGUI)
						EndIf
						;If $l = 5 Then ExitLoop
						If GUICtrlRead($Checkbox_stop) = $GUI_CHECKED Then ExitLoop
					Next
					$games = $games - 1
					MsgBox(262192, "Read Result - Page " & $page, $games & " games found in current page. " & $added & " added.", 3, $WishlistGUI)
					Sleep(500)
					If GUICtrlRead($Checkbox_stop) = $GUI_CHECKED Then ExitLoop
				EndIf
			WEnd
			GUICtrlSetData($Input_title, "")
			GUICtrlSetBkColor($Input_title, Default)
			GUICtrlSetState($Checkbox_next, $GUI_ENABLE)
			GUICtrlSetState($Checkbox_all, $GUI_ENABLE)
			DisableEnableControls($GUI_ENABLE)
		ElseIf $ans = 2 Then
			$ans = MsgBox(262177, "ADD To The Wishlist - " & $user, _
				"Another semblance of automated ADD, is using the" & @LF & _
				"older download and scrape method, that requires a" & @LF & _
				"web connection, and now only partly works. It still" & @LF & _
				"working well enough, to scrape titles from the first" & @LF & _
				"page of your online GOG Wishlist, as well as extract" & @LF & _
				"Price, URL and Game ID. That first page is generally" & @LF & _
				"where new additions are listed." & @LF & @LF & _
				"OK = Download & Scrape to ADD new games." & @LF & _
				"CANCEL = Abort any ADD.", 0, $WishlistGUI)
			If $ans = 1 Then
				DisableEnableControls($GUI_DISABLE)
				GUICtrlSetState($Checkbox_next, $GUI_DISABLE)
				GUICtrlSetState($Checkbox_all, $GUI_DISABLE)
				GUICtrlSetState($Checkbox_stop, $GUI_DISABLE)
				$URL = "https://www.gog.com/u/" & $user & "/wishlist"
				$text = InputBox("Go To Wishlist", "Please check your wishlist URL.", $URL, "", 350, 130, Default, Default, 0, $WishlistGUI)
				If @error = 0 And StringLeft($text, 4) = "http" Then
					GUICtrlSetData($Input_title, " Please Wait - Connecting to GOG ...")
					GUICtrlSetBkColor($Input_title, $COLOR_RED)
					$URL = $text
					$ping = Ping("gog.com", 5000)
					If $ping > 0 Then
						$oIE = _IECreate($URL, 0, 0, 1, 0)
						$err = @error
						If $err = 0 Then
							$html = _IEDocReadHTML($oIE)
							$err = @error
							If $err = 0 And $html <> "" Then
								GUICtrlSetData($Input_title, " Please Wait - Reading downloaded Web Page data")
								GUICtrlSetBkColor($Input_title, $COLOR_LIME)
								$error = ""
								$text = StringSplit($html, "var gogData", 1)
								If $text[0] > 1 Then
									$text = $text[2]
									$text = StringSplit($text, @LF, 1)
									$text = $text[1]
									$lines = StringSplit($text, '"slug":', 1)
									If $lines[0] > 1 Then
										$added = 0
										$nums = _GUICtrlListView_GetItemCount($Listview_items)
										$games = $lines[0]
										For $l = 1 to $games
											$line = $lines[$l]
											$title = StringSplit($line, '"title":"', 1)
											If $title[0] > 1 Then
												$title = $title[2]
												$title = StringSplit($title, '"', 1)
												$title = $title[1]
												$title = StringReplace($title, '\u00ae', '®') ;®
												$title = StringReplace($title, '\u2122', '™') ;™
												$title = StringReplace($title, '\u2013', '-')
												$title = StringReplace($title, "\u2019", "’") ;’
												$title = StringReplace($title, "&amp;", "&")
												If $title <> "" Then
													If IniRead($gamefle, $title, "last", "") = "" Then
														$price = StringSplit($line, '"finalAmount":"', 1)
														$price = $price[2]
														$price = StringSplit($price, '"', 1)
														$price = $price[1]
														$link = StringSplit($line, '"url":"', 1)
														$link = $link[2]
														$link = StringSplit($link, '"', 1)
														$link = $link[1]
														$link = StringReplace($link, "\/", "/")
														$gameID = StringSplit($line, ',"id":', 1)
														$gameID = $gameID[2]
														$gameID = StringSplit($gameID, ',', 1)
														$gameID = $gameID[1]
														;MsgBox(262192, "Title", $title & @LF & $gameID & @LF & $price & @LF & $link, 0, $WishlistGUI)
														$price = StringStripWS($price, 7)
														If StringInStr($price, ".") > 0 Then
															$price = StringSplit($price, '.', 1)
															If StringLen($price[2]) = 1 Then
																$price = $price[1] & "." & $price[2] & "0"
															Else
																$price = $price[1] & "." & $price[2]
															EndIf
														ElseIf $price <> '0' Then
															$price = $price & ".00"
														EndIf
														$start = $price
														$low = $price
														$high = $price
														$prior = $price
														$last = $price
														IniWrite($gamefle, $title, "id", $gameID)
														IniWrite($gamefle, $title, "added", _Now())
														IniWrite($gamefle, $title, "start", $start)
														IniWrite($gamefle, $title, "lowest", $low)
														IniWrite($gamefle, $title, "highest", $high)
														IniWrite($gamefle, $title, "prior", $prior)
														IniWrite($gamefle, $title, "last", $last)
														IniWrite($gamefle, $title, "url", $link)
														$nums = $nums + 1
														$lne = $nums
														GUICtrlCreateListViewItem($lne & "|" & $title & "|" & $start & "|" & $low & "|" & $high & "|" & $prior & "|" & $last & "|" & $link, $Listview_items)
														$low = Number(IniRead($gamefle, $title, "lowest", ""))
														If $low = 0 Then
															; Light Blue
															$color = 0x80FFFF
														ElseIf IsInt($lne / 2) <> 1 Then
															; Pale Pink
															$color = 0xF0D0F0
														Else
															; Pale Green
															$color = 0xC0F0C0
														EndIf
														GUICtrlSetBkColor($lowid + $lne, $color)
														GUICtrlSetData($Group_list, "List Of Games On Wishlist  (" & $lne & ")")
														$bigid = $lowid + $lne + 1
														$e = $lne - 1
														_GUICtrlListView_EnsureVisible($Listview_items, $e, False)
														_GUICtrlListView_SetItemSelected($Listview_items, $e, True, True)
														_GUICtrlListView_ClickItem($Listview_items, $e, "right", False, 1, 1)
														$added = $added + 1
														;If $added = 1 Then ExitLoop
													Else
														; Skipping existing
													EndIf
												EndIf
											EndIf
										Next
										If $games > 0 Then $games = $games - 1
										MsgBox(262192, "Read Result", $games & " games found. " & $added & " added.", 0, $WishlistGUI)
										If $added = 0 Then
											$ans = MsgBox(262177, "Save Query", _
												"HTML can be saved to file for checking." & @LF & @LF & _
												"OK = Save the downloaded HTML." & @LF & _
												"CANCEL = Abort any save.", 0, $WishlistGUI)
											If $ans = 1 Then
												_FileCreate($webfle)
												FileWrite($webfle, $html)
											EndIf
										EndIf
									Else
										$error = 1
										MsgBox(262192, "Split Error 2", "Divider character could not be found!", 0, $WishlistGUI)
									EndIf
								Else
									$error = 1
									MsgBox(262192, "Split Error 1", "Divider character could not be found!", 0, $WishlistGUI)
								EndIf
								If $error = 1 Then
									_FileCreate($webfle)
									FileWrite($webfle, $html)
								EndIf
							Else
								MsgBox(262192, "Html Error", "No data extracted!", 0, $WishlistGUI)
							EndIf
						Else
							MsgBox(262192, "Download Error", "No data returned!", 0, $WishlistGUI)
						EndIf
						_IEQuit($oIE)
					Else
						MsgBox(262192, "Ping Error", "Change the server address or increase timeout!", 0, $WishlistGUI)
					EndIf
				ElseIf StringLeft($text, 4) <> "http" Then
					MsgBox(262192, "Link Error", "URL has not been correctly specified!", 0, $WishlistGUI)
				EndIf
				GUICtrlSetData($Input_title, "")
				GUICtrlSetBkColor($Input_title, Default)
				GUICtrlSetState($Checkbox_next, $GUI_ENABLE)
				GUICtrlSetState($Checkbox_all, $GUI_ENABLE)
				GUICtrlSetState($Checkbox_stop, $GUI_ENABLE)
				DisableEnableControls($GUI_ENABLE)
			EndIf
		EndIf
	Case $msg = $Checkbox_clip
		; Copy URL to clipboard for selected
		If GUICtrlRead($Checkbox_clip) = $GUI_CHECKED Then
			GUICtrlSetData($Button_web, "COPY URL")
			GUICtrlSetTip($Button_web, "Copy URL to clipboard for selected title!")
			GUICtrlSetData($Button_find, "PRICE")
			GUICtrlSetTip($Button_find, "Copy the price to clipboard!")
		ElseIf GUICtrlRead($Checkbox_clip) = $GUI_UNCHECKED Then
			GUICtrlSetData($Button_web, "WEB PAGE")
			GUICtrlSetTip($Button_web, "Go to web page for selected title!")
			GUICtrlSetData($Button_find, "FIND")
			GUICtrlSetTip($Button_find, "Find the specified text!")
		Else
			GUICtrlSetData($Button_web, "WISHLIST")
			GUICtrlSetTip($Button_web, "Go to wishlist web page at GOG!")
			GUICtrlSetData($Button_find, "TITLE")
			GUICtrlSetTip($Button_find, "Copy the title to clipboard!")
		EndIf
	Case $msg = $Checkbox_all
		; Process ALL wishlist pages
		ContinueLoop
		If GUICtrlRead($Checkbox_all) = $GUI_CHECKED Then
			$all = 1
			GUICtrlSetState($Input_page, $GUI_DISABLE)
		Else
			$all = 4
			GUICtrlSetState($Input_page, $GUI_ENABLE)
		EndIf
	Case $msg = $Listview_items Or ($msg > $lowid And $msg < $bigid)
		If $msg = $Listview_items Then
			$colnum = GUICtrlGetState($Listview_items)
			;If $colnum = 0 Or $colnum = 1 Or $colnum = 2 Or $colnum = 3 Or $colnum = 4 Or $colnum = 5 Or $colnum = 6 Then
			If StringInStr("0123456", $colnum) > 0 Then
				SplashTextOn("", "Please Wait!", 200, 120, -1, -1, 33)
				If $slick = 1 Then
					GUISetState($WishlistGUI, @SW_LOCK + @SW_DISABLE)
					_GUICtrlListView_BeginUpdate($Listview_items)
				EndIf
				_GUICtrlListView_SimpleSort($Listview_items, False, $colnum)
				If $slick = 1 Then
					_GUICtrlListView_EndUpdate($Listview_items)
					GUISetState($WishlistGUI, @SW_ENABLE + @SW_UNLOCK)
				EndIf
				SplashOff()
			EndIf
		Else
			$e = _GUICtrlListView_GetSelectedIndices($Listview_items, True)
			If $e[0] = 1 Then
				$e = $e[1]
				$title = _GUICtrlListView_GetItemText($Listview_items, $e, 1)
				GUICtrlSetData($Input_title, $title)
				$current = _GUICtrlListView_GetItemText($Listview_items, $e, 6)
				GUICtrlSetData($Input_price, $currency & $current)
				$gameID = IniRead($gamefle, $title, "id", "")
				GUICtrlSetData($Input_id, $gameID)
			EndIf
		EndIf
		If $show = 1 Then
			$show = ""
		Else
			GUICtrlSetState($Label_time, $GUI_HIDE)
		EndIf
	Case Else
		;;;
	EndSelect
WEnd

Exit


Func CheckForTwoDecimalPlaces($value)
	Local $cents, $digits, $dollars
	If $value <> "" Then
		$digits = StringSplit($value, ".", 1)
		If $digits[0] = 2 Then
			$dollars = $digits[1]
			If $dollars = "" Then $value = "0" & $value
			$cents = $digits[2]
			If StringLen($cents) = 1 Then
				$value = $value & "0"
			EndIf
		Else
			$value = $value & ".00"
		EndIf
	EndIf
	Return $value
EndFunc ;=> CheckForTwoDecimalPlaces

Func CreateBackupListFiles($fle)
	Local $bakfile, $reason, $sze
	$res = ""
	$reason = "(Backup could not be created or replaced.)"
	If FileExists($fle) Then
		$sze = FileGetSize($fle)
		If $sze > 0 Then
			$sze = 1
			While 1
				$bakfile = StringTrimRight($fle, 4)
				$bakfile = StringReplace($bakfile, @ScriptDir, $backups)
				$bakfile = $bakfile & "_" & $sze & ".bak"
				If Not FileExists($bakfile) Then
					$res = FileCopy($fle, $bakfile)
					$sze = ""
					ExitLoop
				Else
					; No backup needed
					If FileGetTime($fle, 0, 1) = FileGetTime($bakfile, 0, 1) Then Return
				EndIf
				If $sze = 9 Then ExitLoop
				$sze = $sze + 1
			WEnd
			If $sze <> "" Then
				; No identical backup found and all 5 backup slots in use,
				; so need to replace oldest and cycle numbering.
				; Oldest backup is always $bakfile & "_1.bak"
				; Most recent backup will always be highest backup after 1, which will be 9 eventually.
				$bakfile = StringTrimRight($bakfile, 6)
				$res = FileMove($bakfile & "_2.bak", $bakfile & "_1.bak", 1)
				If $res = 1 Then
					$res = FileMove($bakfile & "_3.bak", $bakfile & "_2.bak", 0)
					If $res = 1 Then
						$res = FileMove($bakfile & "_4.bak", $bakfile & "_3.bak", 0)
						If $res = 1 Then
							$res = FileMove($bakfile & "_5.bak", $bakfile & "_4.bak", 0)
							If $res = 1 Then
								$res = FileMove($bakfile & "_6.bak", $bakfile & "_5.bak", 0)
								If $res = 1 Then
									$res = FileMove($bakfile & "_7.bak", $bakfile & "_6.bak", 0)
									If $res = 1 Then
										$res = FileMove($bakfile & "_8.bak", $bakfile & "_7.bak", 0)
										If $res = 1 Then
											$res = FileMove($bakfile & "_9.bak", $bakfile & "_8.bak", 0)
											If $res = 1 Then
												$res = FileCopy($fle, $bakfile & "_9.bak")
											EndIf
										EndIf
									EndIf
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			$reason = "(File seems empty.)"
		EndIf
	Else
		$reason = "(File missing.)"
	EndIf
	If $res = "" Then
		MsgBox(262192, "Backup Error", "Something prevented a backup of -" & @LF & $fle & @LF & $reason, 0, $WishlistGUI)
	EndIf
EndFunc ;=> CreateBackupListFiles

Func DisableEnableControls($state)
	GUICtrlSetState($Button_find, $state)
	GUICtrlSetState($Button_web, $state)
	GUICtrlSetState($Checkbox_clip, $state)
	GUICtrlSetState($Button_remove, $state)
	GUICtrlSetState($Button_update, $state)
	GUICtrlSetState($Button_ontop, $state)
	GUICtrlSetState($Button_check, $state)
	If GUICtrlRead($Checkbox_all) = $GUI_CHECKED Then
		GUICtrlSetState($Checkbox_stop, $state)
	ElseIf GUICtrlGetState($Checkbox_stop) = $GUI_DISABLE Or GUICtrlGetState($Checkbox_stop) = 144 Then
		GUICtrlSetState($Checkbox_stop, $state)
	EndIf
	GUICtrlSetState($Input_user, $state)
	GUICtrlSetState($Button_add, $state)
	GUICtrlSetState($Button_urlup, $state)
	GUICtrlSetState($Button_detail, $state)
	GUICtrlSetState($Button_info, $state)
EndFunc ;=> DisableEnableControls

Func LoadTheList()
	Local $higher, $percent
	$percent = IniRead($inifle, "Percent", "check", "")
	$higher = IniRead($inifle, "Higher", "check", "")
	If $percent = "" Or $higher = "" Then
		$read = FileRead($gamefle)
		If $percent = "" Then
			If StringInStr($read, "percent=") > 0 Then
				$percent = 1
			Else
				$percent = 4
				IniWrite($inifle, "Percent", "check", $percent)
			EndIf
		EndIf
		If $higher = "" Then
			If StringInStr($read, "higher=") > 0 Then
				$higher = 1
			Else
				$higher = 4
				IniWrite($inifle, "Higher", "check", $higher)
			EndIf
		EndIf
	EndIf
	$lne = 0
	$games = IniReadSectionNames($gamefle)
	For $n = 1 To $games[0]
		$title = $games[$n]
		$lne = $lne + 1
		If $percent = 1 Then
			IniDelete($gamefle, $title, "percent")
		EndIf
		; NOTE - $last = current price
		$last = IniRead($gamefle, $title, "last", "")
		$prior = IniRead($gamefle, $title, "prior", "")
		$start = IniRead($gamefle, $title, "start", "na")
		$low = IniRead($gamefle, $title, "lowest", "")
		If $higher = 1 Then
			$high = IniRead($gamefle, $title, "higher", "")
			IniWrite($gamefle, $title, "highest", $high)
			IniDelete($gamefle, $title, "higher")
		Else
			$high = IniRead($gamefle, $title, "highest", "")
		EndIf
		$link = IniRead($gamefle, $title, "url", "")
		GUICtrlCreateListViewItem($lne & "|" & $title & "|" & $start & "|" & $low & "|" & $high & "|" & $prior & "|" & $last & "|" & $link, $Listview_items)
		$changed = IniRead($gamefle, $title, "changed", "")
		If $changed <> "" Then
			If $changed = "less" Then
				; Green
				$color = 0x60E000
			ElseIf $changed = "more" Then
				; Red
				$color = 0xF02000
			ElseIf $changed = "subtle" Then
				; Orange
				$color = 0xFF8000
			ElseIf $changed = "fail" Then
				; Pink
				$color = 0xFF80FF
			EndIf
		Else
			$low = Number(IniRead($gamefle, $title, "lowest", ""))
			If $start <> "na" And $low <> "" Then
				$last = Number(IniRead($gamefle, $title, "last", ""))
				$start = Number(IniRead($gamefle, $title, "start", ""))
				If ($last < $start) And ($last = $low) Then
					$last = 1
				Else
					$last = ""
				EndIf
			Else
				$last = ""
			EndIf
			If $low = 0 Then
				; Light Blue
				$color = 0x80FFFF
			ElseIf $last = 1 Then
				; Yellow
				$color = $COLOR_YELLOW
			ElseIf $start = "na" Then
				; Pink
				$color = 0xFF80FF
			ElseIf IsInt($lne / 2) <> 1 Then
				; Pale Pink
				$color = 0xF0D0F0
			Else
				; Pale Green
				$color = 0xC0F0C0
			EndIf
		EndIf
		GUICtrlSetBkColor($lowid + $lne, $color)
	Next
	If $percent = 1 Then
		$percent = 4
		IniWrite($inifle, "Percent", "check", $percent)
	EndIf
	If $higher = 1 Then
		$higher = 4
		IniWrite($inifle, "Higher", "check", $higher)
	EndIf
	GUICtrlSetData($Group_list, "List Of Games On Wishlist  (" & $lne & ")")
	$bigid = $lowid + $lne + 1
EndFunc ;=> LoadTheList

Func SetTheColumnWidths()
	;"No.|Title|Start|Low|High|Prior|Price|URL
	_GUICtrlListView_SetColumnWidth($Listview_items, 0, 35)		; No.
	_GUICtrlListView_SetColumnWidth($Listview_items, 1, 335)	; Title
	_GUICtrlListView_SetColumnWidth($Listview_items, 2, 55)		; Start
	_GUICtrlListView_SetColumnWidth($Listview_items, 3, 55)		; Low
	_GUICtrlListView_SetColumnWidth($Listview_items, 4, 55)		; High
	_GUICtrlListView_SetColumnWidth($Listview_items, 5, 58)		; Prior
	_GUICtrlListView_SetColumnWidth($Listview_items, 6, 55)		; Price
	_GUICtrlListView_SetColumnWidth($Listview_items, 7, 200)	; URL
	; Centering
	_GUICtrlListView_SetColumn($Listview_items, 0, "No.", 35, 2)
	_GUICtrlListView_SetColumn($Listview_items, 2, "Start", 55, 2)
	_GUICtrlListView_SetColumn($Listview_items, 3, "Low", 55, 2)
	_GUICtrlListView_SetColumn($Listview_items, 4, "High", 55, 2)
	_GUICtrlListView_SetColumn($Listview_items, 5, "Prior", 58, 2)
	_GUICtrlListView_SetColumn($Listview_items, 6, "Price", 55, 2)
	;_GUICtrlListView_SetColumn($Listview_items, 7, "URL", 200, 2)
EndFunc ;=> SetTheColumnWidths
