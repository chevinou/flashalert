; ============================================================
;  Alerte - Client
;  Couleurs fixes : urgence=rouge / alerte=orange / info=bleu
;  Fond popup via GUISetBkColor + labels WM_CTLCOLORSTATIC
;  Reste premier plan jusqu'a acquittement
;  Son repete + clignotement si non acquitte
; ============================================================

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <WinAPIGdi.au3>
#include <WinAPI.au3>
#include <File.au3>
#include <Misc.au3>

If _Singleton("Alerte_Client", 1) = 0 Then Exit

Opt("TrayMenuMode", 3)
Opt("TrayIconHide", 0)

Global $icoFile = @ScriptDir & "\client.ico"
If FileExists($icoFile) Then TraySetIcon($icoFile)
TraySetToolTip("Alerte - En ecoute")

Global $iniFile = @ScriptDir & "\alerte.ini"
If Not FileExists($iniFile) Then
    MsgBox(16, "Alerte Client", "Fichier alerte.ini introuvable :" & @CRLF & $iniFile)
    Exit
EndIf
Global $msgFile    = IniRead($iniFile, "Chemins",  "Message",    @ScriptDir & "\..\shared\message.txt")
Global $logFile    = IniRead($iniFile, "Chemins",  "Log",        @ScriptDir & "\..\shared\log.txt")
Global $wavFile    = IniRead($iniFile, "Chemins",  "Son",        @ScriptDir & "\..\shared\alerte.wav")
Global $intervalle = Int(IniRead($iniFile, "Options", "Intervalle", 3000))
Global $sonRepeat  = Int(IniRead($iniFile, "Options", "SonRepeat",  15))

Global $dernierContenu = ""
Global $derniereDate   = ""
If FileExists($msgFile) Then
    $dernierContenu = FileRead($msgFile)
    $derniereDate   = FileGetTime($msgFile, 0, 1)
EndIf

; Variables globales pour le handler WM_CTLCOLORSTATIC du client
; (reinitialises a chaque alerte)
Global $g_hBrushFond   = 0
Global $g_hBrushAccent = 0
Global $g_hBrushGris   = 0
Global $g_hBtnFermer   = 0
Global $g_hLblTitre    = 0
Global $g_hLblCorps    = 0
Global $g_hLblInfo     = 0
Global $g_hLblBadge    = 0
Global $g_hLblSep      = 0
Global $g_clrTexte     = 0x00FFFFFF
Global $g_clrGris      = 0x00EEEEEE
Global $g_clrInfo      = 0x00CCCCCC

; ---- Couleurs par type (BGR pour GDI CreateSolidBrush) ----
; GDI COLORREF = 0x00BBGGRR
Func _BgrFond($type)
    If $type = "urgence" Then Return 0x001A1A7B   ; rouge fonce BGR de #7B1A1A
    If $type = "alerte"  Then Return 0x0000317D   ; orange fonce BGR de #7D3100
    Return 0x007A3B0D                             ; bleu fonce  BGR de #0D3B7A
EndFunc

Func _BgrAccent($type)
    If $type = "urgence" Then Return 0x005053EF   ; rouge vif  BGR de #EF5350
    If $type = "alerte"  Then Return 0x004370FF   ; orange vif BGR de #FF7043
    Return 0x00F5A542                              ; bleu vif   BGR de #42A5F5
EndFunc

Func _RgbFond($type)
    If $type = "urgence" Then Return 0x7B1A1A
    If $type = "alerte"  Then Return 0x7D3100
    Return 0x0D3B7A
EndFunc

; ---- Handler WM_CTLCOLORSTATIC pour la popup client ----
GUIRegisterMsg(0x0138, "WM_CTLCOLOR_CLIENT")

Func WM_CTLCOLOR_CLIENT($hWnd, $iMsg, $wParam, $lParam)
    #forceref $hWnd, $iMsg
    Local $hDC = $wParam
    ; Badge, titre, corps, info, separateur : fond = couleur principale
    If $lParam = $g_hLblBadge Or $lParam = $g_hLblTitre Or $lParam = $g_hLblCorps Or $lParam = $g_hLblSep Then
        _WinAPI_SetBkMode($hDC, 1)
        _WinAPI_SetTextColor($hDC, $g_clrTexte)
        Return $g_hBrushFond
    EndIf
    If $lParam = $g_hLblInfo Then
        _WinAPI_SetBkMode($hDC, 1)
        _WinAPI_SetTextColor($hDC, $g_clrInfo)
        Return $g_hBrushFond
    EndIf
    ; Bouton "J'ai lu" : fond accent
    If $lParam = $g_hBtnFermer Then
        _WinAPI_SetBkMode($hDC, 1)
        _WinAPI_SetTextColor($hDC, $g_clrTexte)
        Return $g_hBrushAccent
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc

; ---- Boucle poll ----
While True
    Sleep($intervalle)
    If Not FileExists($msgFile) Then ContinueLoop
    Local $dateActuelle = FileGetTime($msgFile, 0, 1)
    If $dateActuelle <> $derniereDate Then
        $derniereDate = $dateActuelle
        Local $contenu = FileRead($msgFile)
        If $contenu <> "" And $contenu <> $dernierContenu Then
            $dernierContenu = $contenu
            AfficherAlerte($contenu)
        EndIf
    EndIf
WEnd

; ============================================================
Func _JouerSon($type)
    If FileExists($wavFile) Then
        SoundPlay($wavFile, 0)   ; 0 = non bloquant
        Return
    EndIf
    If $type = "urgence" Then
        SoundPlay(@WindowsDir & "\Media\Windows Critical Stop.wav", 0)
    ElseIf $type = "alerte" Then
        SoundPlay(@WindowsDir & "\Media\Windows Exclamation.wav", 0)
    Else
        SoundPlay(@WindowsDir & "\Media\Windows Notify.wav", 0)
    EndIf
EndFunc

Func AfficherAlerte($contenu)
    $contenu = StringStripWS($contenu, 3)
    If $contenu = "" Then Return

    ; Parsing : TYPE|Titre|Corps|Expediteur|Horodatage
    Local $parts      = StringSplit($contenu, "|", 2)
    Local $type       = "info"
    Local $titre      = "Alerte"
    Local $corps      = $contenu
    Local $expediteur = ""
    Local $horodatage = ""

    If UBound($parts) >= 1 Then $type       = StringLower(StringStripWS($parts[0], 3))
    If UBound($parts) >= 2 Then $titre      = StringStripWS($parts[1], 3)
    If UBound($parts) >= 3 Then $corps      = StringStripWS($parts[2], 3)
    If UBound($parts) >= 4 Then $expediteur = StringStripWS($parts[3], 3)
    If UBound($parts) >= 5 Then $horodatage = StringStripWS($parts[4], 3)

    ; Creer les brushes GDI pour ce type
    $g_hBrushFond   = _WinAPI_CreateSolidBrush(_BgrFond($type))
    $g_hBrushAccent = _WinAPI_CreateSolidBrush(_BgrAccent($type))

    Local $guiW = 500
    Local $guiH = 230
    Local $posX = @DesktopWidth - $guiW - 20
    Local $posY = 30

    Local $hGui = GUICreate("Alerte", $guiW, $guiH, $posX, $posY, $WS_POPUP, $WS_EX_TOPMOST)
    GUISetBkColor(_RgbFond($type))
    If FileExists($icoFile) Then GUISetIcon($icoFile)

    ; Badge type
    Local $hLblBadge = GUICtrlCreateLabel("  " & StringUpper($type), 0, 0, $guiW, 26, BitOR(0, 0x100))
    GUICtrlSetFont($hLblBadge, 9, 800, 0, "Segoe UI")
    GUICtrlSetColor($hLblBadge, 0xFFFFFF)
    GUICtrlSetBkColor($hLblBadge, 0x000001)   ; force repaint via handler
    $g_hLblBadge = GUICtrlGetHandle($hLblBadge)

    ; Titre
    Local $hLblTitre = GUICtrlCreateLabel($titre, 12, 30, $guiW - 20, 42)
    GUICtrlSetFont($hLblTitre, 14, 800, 0, "Segoe UI")
    GUICtrlSetColor($hLblTitre, 0xFFFFFF)
    GUICtrlSetBkColor($hLblTitre, 0x000001)
    $g_hLblTitre = GUICtrlGetHandle($hLblTitre)

    ; Corps
    Local $hLblCorps = GUICtrlCreateLabel($corps, 12, 76, $guiW - 20, 55)
    GUICtrlSetFont($hLblCorps, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor($hLblCorps, 0xEEEEEE)
    GUICtrlSetBkColor($hLblCorps, 0x000001)
    $g_hLblCorps = GUICtrlGetHandle($hLblCorps)

    ; Expediteur
    Local $infoTxt = ""
    If $expediteur <> "" Then
        $infoTxt = "De : " & $expediteur
        If $horodatage <> "" Then $infoTxt = $infoTxt & "   -   " & $horodatage
    EndIf
    Local $hLblInfo = GUICtrlCreateLabel($infoTxt, 12, 134, $guiW - 20, 18)
    GUICtrlSetFont($hLblInfo, 8, 400, 2, "Segoe UI")
    GUICtrlSetColor($hLblInfo, 0xCCCCCC)
    GUICtrlSetBkColor($hLblInfo, 0x000001)
    $g_hLblInfo = GUICtrlGetHandle($hLblInfo)

    ; Separateur (label vide avec fond accent)
    Local $hLblSep = GUICtrlCreateLabel("", 12, 155, $guiW - 24, 1)
    GUICtrlSetBkColor($hLblSep, 0x000001)
    $g_hLblSep = GUICtrlGetHandle($hLblSep)

    ; Bouton J'ai lu (label cliquable, fond accent)
    Local $btnW = 160
    Local $btnH = 34
    Local $btnX = ($guiW - $btnW) / 2
    Local $btnY = $guiH - 48
    Local $hBtnFermer = GUICtrlCreateLabel("OK  -  J'ai lu", $btnX, $btnY, $btnW, $btnH, BitOR(1, 0x100))
    GUICtrlSetFont($hBtnFermer, 10, 700, 0, "Segoe UI")
    GUICtrlSetColor($hBtnFermer, 0xFFFFFF)
    GUICtrlSetBkColor($hBtnFermer, 0x000002)   ; valeur differente pour que le handler le distingue
    $g_hBtnFermer = GUICtrlGetHandle($hBtnFermer)

    GUISetState(@SW_SHOW)
    WinSetOnTop($hGui, "", 1)

    _JouerSon($type)
    _EcrireLogClient($type, $titre)
    WinActivate($hGui)

    Local $tSon    = TimerInit()
    Local $tCligno = TimerInit()

    While True
        ; GUIGetMsg(1) = mode avance, retourne array [event, hwnd, ctrlid, ...]
        Local $aMsg    = GUIGetMsg(1)
        Local $evtMsg  = $aMsg[0]
        Local $evtHwnd = $aMsg[1]

        ; Fermeture uniquement par clic sur le bouton de notre fenetre
        If $evtMsg = $hBtnFermer And $evtHwnd = $hGui Then ExitLoop

        ; Maintien premier plan + clignotement
        If Not WinActive($hGui) Then
            WinSetOnTop($hGui, "", 1)
            If TimerDiff($tCligno) > 800 Then
                $tCligno = TimerInit()
                Local $stFlash = DllStructCreate("uint;hwnd;dword;uint;dword")
                DllStructSetData($stFlash, 1, DllStructGetSize($stFlash))
                DllStructSetData($stFlash, 2, $hGui)
                DllStructSetData($stFlash, 3, 3)
                DllStructSetData($stFlash, 4, 2)
                DllStructSetData($stFlash, 5, 0)
                DllCall("user32.dll", "bool", "FlashWindowEx", "ptr", DllStructGetPtr($stFlash))
            EndIf
        EndIf

        ; Son repete
        If TimerDiff($tSon) > ($sonRepeat * 1000) Then
            $tSon = TimerInit()
            _JouerSon($type)
        EndIf

        Sleep(100)
    WEnd

    ; Liberer brushes
    _WinAPI_DeleteObject($g_hBrushFond)
    _WinAPI_DeleteObject($g_hBrushAccent)
    $g_hBrushFond   = 0
    $g_hBrushAccent = 0
    $g_hBtnFermer   = 0
    $g_hLblTitre    = 0
    $g_hLblCorps    = 0
    $g_hLblInfo     = 0
    $g_hLblBadge    = 0
    $g_hLblSep      = 0

    GUIDelete($hGui)
EndFunc

Func _EcrireLogClient($logType, $logTitre)
    Local $ts   = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    Local $hLog = FileOpen($logFile, 1)
    If $hLog = -1 Then Return
    FileWriteLine($hLog, $ts & " | RECEPTION: " & @UserName & "@" & @ComputerName & " | " & $logType & " | " & $logTitre)
    FileClose($hLog)
EndFunc
