Global $hWindow = WinGetHandle("Replay")
Global $hActive = WinGetHandle("Guild Wars 2")
Local $f30 = 0
Local $lrdl = 0

While (True)
 ;$hActive = WinGetHandle("[ACTIVE]")
 WinActivate($hWindow)
 Sleep(200)
 MouseWheel("DOWN", 20)
 ;For $i = 1 to 10
 ;ControlSend($hWindow, "", "", "{DOWN}",1)
 ;Next
 Sleep(200)
 WinActivate($hActive)
 Opt("SendKeyDelay",(40))
 Opt("SendKeyDownDelay", (150))
 sleep(100)
 $f30 += 1
 If $f30 = 5 then
    ControlSend($hActive, "", "", "F",1)
	$f30 = 0
	sleep(500)
 EndIf
 $lrdl += 1
 If $lrdl = 5 Then
    sleep(500)
    Opt("SendKeyDownDelay", (180))
    For $i = 1 to 2
       If $i = 1 Then
	      ControlSend($hActive, "", "", "{LEFT}")
       EndIf
       If $i = 2 Then
          ControlSend($hActive, "", "", "{RIGHT}")
       EndIf
       Sleep(100)
	Next
    $lrdl = 0
 EndIf
 ;Sleep(1000)
 Opt("SendKeyDelay",(5))
 Opt("SendKeyDownDelay", (5))
 sleep(7000)
WEnd