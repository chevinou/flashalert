; ============================================================
;  AlerteAH - Appelant
;  Couleurs fixes par type : urgence=rouge / alerte=orange / info=bleu
;  Boutons = Labels WM_CTLCOLORSTATIC (couleurs garanties Win10/11)
; ============================================================

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <WinAPIGdi.au3>
#include <File.au3>
#include <Array.au3>
#include <Misc.au3>

If _Singleton("Alerte_Appelant", 1) = 0 Then
    MsgBox(48, "Alerte", "Alerte est deja en cours d'execution.")
    Exit
EndIf

; ---- Configuration ----
Global $iniFile = @ScriptDir & "\alerte.ini"
If Not FileExists($iniFile) Then
    MsgBox(16, "AlerteAH - Erreur", "Fichier de configuration introuvable :" & @CRLF & $iniFile)
    Exit
EndIf
Global $msgFile    = IniRead($iniFile, "Chemins", "Message",  @ScriptDir & "\..\shared\message.txt")
Global $menuFile   = IniRead($iniFile, "Chemins", "Menu",     @ScriptDir & "\..\shared\menu.txt")
Global $logFile    = IniRead($iniFile, "Chemins", "Log",      @ScriptDir & "\..\shared\log.txt")
Global $delai      = Int(IniRead($iniFile, "Options", "Delai", 10))
Global $expediteur = @UserName & " (" & @ComputerName & ")"

; ---- Lecture du menu ----
; FORMAT : Texte_bouton|TYPE|Titre|Corps  (4 champs, sans couleur)
If Not FileExists($menuFile) Then
    MsgBox(16, "Alerte - Erreur", "Fichier menu introuvable :" & @CRLF & $menuFile)
    Exit
EndIf

Global $aBoutons[50][4]   ; [n][0]=label [n][1]=type [n][2]=titre [n][3]=corps
Global $nBoutons = 0
Global $indexPrincipal = 0

Local $hMenu = FileOpen($menuFile, 0)
If $hMenu = -1 Then
    MsgBox(16, "Alerte - Erreur", "Impossible de lire " & $menuFile)
    Exit
EndIf
Local $estPrincipal = False
While True
    Local $ligne = FileReadLine($hMenu)
    If @error Then ExitLoop
    $ligne = StringStripWS($ligne, 3)
    If $ligne = "" Or StringLeft($ligne, 1) = ";" Then ContinueLoop
    If $ligne = "[PRINCIPAL]" Then
        $estPrincipal = True
        ContinueLoop
    ElseIf $ligne = "[BOUTON]" Then
        $estPrincipal = False
        ContinueLoop
    EndIf
    Local $parts = StringSplit($ligne, "|", 2)
    If UBound($parts) >= 4 Then
        $aBoutons[$nBoutons][0] = StringStripWS($parts[0], 3)
        $aBoutons[$nBoutons][1] = StringLower(StringStripWS($parts[1], 3))
        $aBoutons[$nBoutons][2] = StringStripWS($parts[2], 3)
        $aBoutons[$nBoutons][3] = StringStripWS($parts[3], 3)
        If $estPrincipal Then
            $indexPrincipal = $nBoutons
            $estPrincipal = False
        EndIf
        $nBoutons += 1
        If $nBoutons >= 50 Then ExitLoop
    EndIf
WEnd
FileClose($hMenu)

If $nBoutons = 0 Then
    MsgBox(16, "AlerteAH - Erreur", "Aucun bouton defini dans " & $menuFile)
    Exit
EndIf

; ---- Couleur de fond par type (BGR pour CreateSolidBrush) ----
; GDI COLORREF = 0x00BBGGRR
Func _BgrFond($type, $estPrinc)
    If $type = "urgence" Or $estPrinc Then Return 0x002B2BC0   ; rouge  #C02B2B
    If $type = "alerte"              Then Return 0x001478E0   ; orange #E07814
    Return 0x00A05A14   ; bleu   #145AA0
EndFunc

; Couleur texte : toujours blanc
Global Const $CLR_TEXTE = 0x00FFFFFF

; ---- Dimensions ----
Global Const $BTN_H  = 52
Global Const $BTN_W  = 440
Global Const $MARGE  = 10
Global Const $ANN_H  = 28
Global Const $GUI_W  = $BTN_W + $MARGE * 2
Global Const $HEAD_H = 36
Global Const $BAR_H  = 20
Global Const $GUI_H  = $HEAD_H + $nBoutons * ($BTN_H + $MARGE) + $MARGE + $BAR_H + $MARGE + $ANN_H + $MARGE

; ---- Creation GUI ----
Global $hGUI = GUICreate("Alerte", $GUI_W, $GUI_H, -1, -1, $WS_POPUP, $WS_EX_TOPMOST)
GUISetBkColor(0x1A1A2E)
Local $icoFile = @ScriptDir & "\appelant.ico"
If FileExists($icoFile) Then GUISetIcon($icoFile)

; Titre
Local $lblHead = GUICtrlCreateLabel("  ALERTE  -  Choisissez une alerte", 0, 0, $GUI_W, $HEAD_H)
GUICtrlSetFont($lblHead, 12, 800, 0, "Segoe UI")
GUICtrlSetColor($lblHead, 0xFFD54F)
GUICtrlSetBkColor($lblHead, 0x1A1A2E)

; Boutons (labels cliquables)
Global $aBtnCtrl[$nBoutons]
Global $aBtnBrush[$nBoutons]   ; handles GDI brush pour WM_CTLCOLORSTATIC

For $i = 0 To $nBoutons - 1
    Local $y = $HEAD_H + $i * ($BTN_H + $MARGE)
    Local $txt = $aBoutons[$i][0]
    If $i = $indexPrincipal Then $txt = ">> " & $txt & " <<"

    ; SS_CENTER=1, SS_NOTIFY=0x100 -> label cliquable centre
    $aBtnCtrl[$i] = GUICtrlCreateLabel($txt, $MARGE, $y, $BTN_W, $BTN_H, BitOR(1, 0x100))
    GUICtrlSetFont($aBtnCtrl[$i], 11, 700, 0, "Segoe UI")
    GUICtrlSetColor($aBtnCtrl[$i], 0xFFFFFF)
    GUICtrlSetBkColor($aBtnCtrl[$i], 0x000000)   ; valeur fictive, remplacee par WM_CTLCOLORSTATIC

    ; Creer le brush GDI pour ce bouton
    $aBtnBrush[$i] = _WinAPI_CreateSolidBrush(_BgrFond($aBoutons[$i][1], ($i = $indexPrincipal)))
Next

; Compte a rebours
Local $yBar = $HEAD_H + $nBoutons * ($BTN_H + $MARGE) + $MARGE
Global $lblCompte = GUICtrlCreateLabel("Declenchement automatique dans " & $delai & "s", $MARGE, $yBar, $BTN_W, $BAR_H)
GUICtrlSetFont($lblCompte, 9, 400, 2, "Segoe UI")
GUICtrlSetColor($lblCompte, 0x9E9E9E)
GUICtrlSetBkColor($lblCompte, 0x1A1A2E)

; Bouton Annuler
Local $yAnn = $yBar + $BAR_H + $MARGE
Global $btnAnnuler = GUICtrlCreateLabel("  X  Annuler (missclic)", $MARGE, $yAnn, $BTN_W, $ANN_H, BitOR(1, 0x100))
GUICtrlSetFont($btnAnnuler, 9, 700, 0, "Segoe UI")
GUICtrlSetColor($btnAnnuler, 0xCCCCCC)
GUICtrlSetBkColor($btnAnnuler, 0x37474F)
Global $hBrushAnn = _WinAPI_CreateSolidBrush(0x004F4737)   ; BGR de 0x37474F

; ---- Handler WM_CTLCOLORSTATIC : force couleur fond+texte sur chaque label ----
GUIRegisterMsg(0x0138, "WM_CTLCOLORSTATIC_HANDLER")   ; WM_CTLCOLORSTATIC = 0x0138

Func WM_CTLCOLORSTATIC_HANDLER($hWnd, $iMsg, $wParam, $lParam)
    #forceref $hWnd, $iMsg
    Local $hDC = $wParam
    ; Verifier si c'est un de nos boutons colores
    For $i = 0 To $nBoutons - 1
        If $lParam = GUICtrlGetHandle($aBtnCtrl[$i]) Then
            _WinAPI_SetTextColor($hDC, $CLR_TEXTE)
            _WinAPI_SetBkMode($hDC, 1)   ; TRANSPARENT = 1 pour que le texte ne bave pas
            Return $aBtnBrush[$i]
        EndIf
    Next
    If $lParam = GUICtrlGetHandle($btnAnnuler) Then
        _WinAPI_SetTextColor($hDC, 0x00CCCCCC)
        _WinAPI_SetBkMode($hDC, 1)
        Return $hBrushAnn
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc

GUISetState(@SW_SHOW)
WinSetOnTop($hGUI, "", 1)

; ---- Boucle principale ----
Local $tStart      = TimerInit()
Local $choixIndex  = -1
Local $dernSeconde = -1

While True
    Local $guiMsg  = GUIGetMsg()
    Local $elapsed = TimerDiff($tStart) / 1000
    Local $restant = $delai - Int($elapsed)

    If Int($elapsed) <> $dernSeconde Then
        $dernSeconde = Int($elapsed)
        If $restant > 0 Then
            GUICtrlSetData($lblCompte, "Declenchement automatique dans " & $restant & "s  -  Annuler pour stopper")
        Else
            GUICtrlSetData($lblCompte, "Declenchement automatique en cours...")
        EndIf
    EndIf

    If $guiMsg = $GUI_EVENT_CLOSE Or $guiMsg = $btnAnnuler Then ExitLoop

    For $i = 0 To $nBoutons - 1
        If $guiMsg = $aBtnCtrl[$i] Then
            $choixIndex = $i
            ExitLoop 2
        EndIf
    Next

    If $elapsed >= $delai Then
        $choixIndex = $indexPrincipal
        ExitLoop
    EndIf

    Sleep(10)
WEnd

; Liberer les brushes GDI
For $i = 0 To $nBoutons - 1
    _WinAPI_DeleteObject($aBtnBrush[$i])
Next
_WinAPI_DeleteObject($hBrushAnn)

GUIDelete($hGUI)
If $choixIndex >= 0 Then EnvoyerAlerte($choixIndex)
Exit

; ============================================================
Func EnvoyerAlerte($idx)
    Local $typeAlerte  = $aBoutons[$idx][1]
    Local $titreAlerte = $aBoutons[$idx][2]
    Local $corpsAlerte = $aBoutons[$idx][3]
    Local $labelBouton = $aBoutons[$idx][0]
    Local $ts = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    ; Format : TYPE|Titre|Corps|Expediteur|Horodatage
    Local $ligne = $typeAlerte & "|" & $titreAlerte & "|" & $corpsAlerte & "|" & $expediteur & "|" & $ts
    Local $hFile = FileOpen($msgFile, 2)
    If $hFile = -1 Then
        MsgBox(16, "Alerte - Erreur", "Impossible d'ecrire dans :" & @CRLF & $msgFile)
        Return
    EndIf
    FileWrite($hFile, $ligne)
    FileClose($hFile)
    _EcrireLog($labelBouton, $ligne)
    MsgBox(64, "Alerte - Alerte envoyee", "Alerte envoyee :" & @CRLF & @CRLF & $labelBouton, 3)
EndFunc

Func _EcrireLog($logLabel, $logMsg)
    Local $ts   = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC
    Local $hLog = FileOpen($logFile, 1)
    If $hLog = -1 Then Return
    FileWriteLine($hLog, $ts & " | APPELANT: " & $expediteur & " | " & $logLabel & " | " & StringReplace($logMsg, @CRLF, " "))
    FileClose($hLog)
EndFunc
