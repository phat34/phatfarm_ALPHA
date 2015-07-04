Global $hWindow = WinGetHandle("Replay")
Global $hActive

While (True)
 $hActive = WinGetHandle("[ACTIVE]")
 WinActivate($hWindow)
 Sleep(100)
 MouseWheel("DOWN", 20)
 ;For $i = 1 to 10
 ;ControlSend($hWindow, "", "", "{DOWN}",1)
 ;Next
 Sleep(100)
 WinActivate($hActive)
 sleep(7000)
WEnd