$psreadlineoptionss = get-psreadlineoption

Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -historysavestyle saveincrementally
Set-PSReadLineOption -vimodeindicator Cursor
Set-PSReadLineOption -bellstyle None
Set-PSReadLineOption -PredictionSource History
#Set-PSReadLineOption -PredictionViewStyle InLineView
Set-PSReadLineOption -EditMode vi
Set-PSReadLineOption -HistorySearchCursorMovesToEnd 


function OnViModeChange {
    if ($args[0] -eq 'Command') {
        # clear the cursor back to default
        Write-Host -NoNewLine "`e[0 q"
    } else {
        # Set the cursor to a blinking line.
        Write-Host -NoNewLine "`e[5 q"
    }
}
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler {
    if ($args[0] -eq 'Command') {
        # clear the cursor back to default
        Write-Host -NoNewLine "`e[0 q"
    } else {
        # Set the cursor to a blinking line.
        Write-Host -NoNewLine "`e[5 q"
    }
}

Set-PSReadLineOption -Colors @{ InlinePrediction = '[34m'}

#colors

$ColorDefault = '[0m' #Returns all attributes to the default state prior to modification
$ColorBoldBright = '[1' #Applies brightness/intensity flag to foreground color
$ColorUnderline = '[4' #Adds underline
$ColorNoUnderline = '[24' #Removes underline
$ColorNegative = '[7' #Swaps foreground and background colors
$ColorPositiveNoNegative = '[27' #Returns foreground/background to normal

$ColorForegroundBlack = '[30m'
$ColorForegroundRed = '[31m'
$ColorForegroundGreen = '[32m'
$ColorForegroundYellow = '[33m'
$ColorForegroundBlue = '[34m'
$ColorForegroundMagenta = '[35m'
$ColorForegroundCyan = '[36m'
$ColorForegroundWhite = '[37m'
$ColorForegroundExtended = '[38m'
$ColorForegroundGray = '[90m'
$ColorForegroundDefault = '[39m'

$ColorForegroundBrightBlack = '[90m'
$ColorForegroundBrightRed = '[91m'
$ColorForegroundBrightGreen = '[92m'
$ColorForegroundBrightYellow = '[93m'
$ColorForegroundBrightBlue = '[94m'
$ColorForegroundBrightMagenta = '[95m'
$ColorForegroundBrightCyan = '[96m'
$ColorForegroundBrightGray = '[97m'
$ColorForegroundBrightWhite = '[97m'

$ColorBackgroundBlack = '[40m'
$ColorBackgroundRed = '[41m'
$ColorBackgroundGreen = '[42m'
$ColorBackgroundYellow = '[43m'
$ColorBackgroundBlue = '[44m'
$ColorBackgroundMagenta = '[45m'
$ColorBackgroundCyan = '[46m'
$ColorBackgroundWhite = '[47m'
$ColorBackgroundExtended = '[48m'
$ColorBackgroundGray = '[100m'
$ColorBackgroundDefault = '[49m'

$ColorBackgroundBrightBlack = '[100m'
$ColorBackgroundBrightRed = '[101m'
$ColorBackgroundBrightGreen = '[102m'
$ColorBackgroundBrightYellow = '[103m'
$ColorBackgroundBrightBlue = '[104m'
$ColorBackgroundBrightMagenta = '[105m'
$ColorBackgroundBrightCyan = '[106m'
$ColorBackgroundBrightGray = '[107m'
$ColorBackgroundBrightWhite = '[107m'

$psstyle.fileinfo.directory = $ColorForegroundGreen
$psstyle.fileinfo.executable = $ColorForegroundBrightYellow
$psstyle.FileInfo.extension.clear()
$psstyle.FileInfo.extension.add('.csv', $colorforegroundgray)
#$psstyle.Formatting.TableHeader = $ColorForegroundBlue
#$psstyle.Formatting.FormatAccent = $ColorForegroundBlue
$psstyle.Formatting.TableHeader = $ColorBackgroundBlue
$psstyle.Formatting.FormatAccent = $ColorBackgroundBlue

$PSStyle.OutputRendering = 'Host'


#key handlers
$script:PSReadlineFunctions_ConsoleBufferWidthSave = [console]::bufferwidth

Remove-PSReadlineKeyHandler -chord ctrl+d -vimode command
Remove-PSReadlineKeyHandler -chord ctrl+d 
Remove-PSReadlineKeyHandler -chord ctrl+r -vimode insert
Remove-PSReadlineKeyHandler -chord ctrl+r  -vimode command
Remove-PSReadlineKeyHandler -chord ctrl+v 
Remove-PSReadlineKeyHandler -chord ctrl+v  -vimode command

Set-PSReadlineKeyHandler -Key 'Ctrl+w'  -Function UnixWordRubout -vimode Insert
#Set-PSReadlineKeyHandler -Key 'Ctrl+u' -Function BackwardKillLine -vimode Insert
Set-PSReadlineKeyHandler -Key Tab  -Function Complete -vimode Insert
Set-PSReadlineKeyHandler -Key 'Ctrl+e'  -Function ScrollDisplayDownLine -ViMode Command
Set-PSReadlineKeyHandler -Key 'Ctrl+y'  -Function ScrollDisplayUpLine -ViMode Command
Set-PSReadlineKeyHandler -Key F8  -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key Shift+F8  -Function HistorySearchForward
set-psreadlinekeyhandler -key 'shift+5' -function GotoBrace -vimode command

set-psreadlinekeyhandler -key 'ctrl+r' -function Redo -vimode command

# `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
# This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
Set-PSReadLineKeyHandler -Key RightArrow `
                         -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
                         -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -lt $line.Length) {
        [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
    }
}

Set-PSReadlineKeyHandler -Key Ctrl+i -BriefDescription ConvertFromTabbedCsv -LongDescription "Grab the clipboard text and execute ConvertFrom-Csv with tab as a delimiter" -ScriptBlock {


    param($key, $arg)

    $data = Get-Clipboard -raw

    [microsoft.powershell.PSConsoleReadLine]::Insert("@'`n")
    [microsoft.powershell.psconsolereadline]::Insert($data)
    [microsoft.powershell.PSConsoleReadLine]::Insert("`n'@")
    [microsoft.powershell.PSConsoleReadLine]::Insert(" | ConvertFrom-Csv -Delimiter ""`t""")
}

Set-PSReadlineKeyHandler -Key Ctrl+shift+h -BriefDescription PasteAsHereStringFromGetClipboard -LongDescription "Paste the clipboard text as a here string using Get-Clipboard" -ScriptBlock {


    param($key, $arg)

    $data = Get-Clipboard -raw


    [microsoft.powershell.PSConsoleReadLine]::Insert("@'`n")
    [microsoft.powershell.psconsolereadline]::Insert($data)
    [microsoft.powershell.PSConsoleReadLine]::Insert("`n'@")
}


Set-PSReadlineKeyHandler -Key Ctrl+h -BriefDescription PasteAsHereString -LongDescription "Paste the clipboard text as a here string" -ScriptBlock {

    param($key, $arg)

    [microsoft.powershell.PSConsoleReadLine]::Insert("@'`n")
    [microsoft.powershell.psconsolereadline]::paste($null,$null)
    [microsoft.powershell.PSConsoleReadLine]::Insert("`n'@")

}

Set-PSReadlineKeyHandler -Key Alt+l  -BriefDescription ScrollBufferRight  -LongDescription "Scroll right in Console Buffer"  -vimode Command -ScriptBlock {
    param($key, $arg)

    $newleft = [console]::windowleft + [console]::windowwidth
    if ($newleft -gt [console]::bufferwidth - [console]::windowwidth){
         $newleft = [console]::bufferwidth - [console]::windowwidth
    }
    [console]::windowleft = $newleft
}

Set-PSReadlineKeyHandler -Key Alt+h  -BriefDescription ScrollBufferLeft  -LongDescription "Scroll left in Console Buffer" -vimode Command  -ScriptBlock {
    param($key, $arg)

    $newleft = [console]::windowleft - [console]::windowwidth
    if ($newleft -lt 0){
        $newleft = 0
    }
    [console]::windowleft = $newleft
}

Set-PSReadlineKeyHandler -Key Alt+j  -BriefDescription ScrollBufferDown  -LongDescription "Scroll down in Console Buffer"  -vimode Command -ScriptBlock {
    param($key, $arg)

    $newtop = [console]::windowtop + [console]::windowheight
    if ($newtop -gt [console]::bufferheight - [console]::windowheight){
         $newtop = [console]::bufferheight - [console]::windowheight
    }
    [console]::windowtop = $newtop
}

Set-PSReadlineKeyHandler -Key Alt+k  -BriefDescription ScrollBufferUp  -LongDescription "Scroll up in Console Buffer"  -vimode Command -ScriptBlock {
    param($key, $arg)

    $newtop = [console]::windowtop - [console]::windowheight
    if ($newtop -lt 0){
        $newtop = 0
    }
    [console]::windowtop = $newtop
}
Set-PSReadlineKeyHandler -Key Alt+l  -BriefDescription ScrollBufferRight  -LongDescription "Scroll right in Console Buffer"  -vimode Insert -ScriptBlock {
    param($key, $arg)

    $newleft = [console]::windowleft + [console]::windowwidth
    if ($newleft -gt [console]::bufferwidth - [console]::windowwidth){
         $newleft = [console]::bufferwidth - [console]::windowwidth
    }
    [console]::windowleft = $newleft
}

Set-PSReadlineKeyHandler -Key Alt+h  -BriefDescription ScrollBufferLeft  -LongDescription "Scroll left in Console Buffer" -vimode Insert  -ScriptBlock {
    param($key, $arg)

    $newleft = [console]::windowleft - [console]::windowwidth
    if ($newleft -lt 0){
        $newleft = 0
    }
    [console]::windowleft = $newleft
}
Set-PSReadlineKeyHandler -Key Alt+j  -BriefDescription ScrollBufferDown  -LongDescription "Scroll down in Console Buffer"  -vimode Insert -ScriptBlock {
    param($key, $arg)

    $newtop = [console]::windowtop + [console]::windowheight
    if ($newtop -gt [console]::bufferheight - [console]::windowheight){
         $newtop = [console]::bufferheight - [console]::windowheight
    }
    [console]::windowtop = $newtop
}

Set-PSReadlineKeyHandler -Key Alt+k  -BriefDescription ScrollBufferUp  -LongDescription "Scroll up in Console Buffer"  -vimode Insert -ScriptBlock {
    param($key, $arg)

    $newtop = [console]::windowtop - [console]::windowheight
    if ($newtop -lt 0){
        $newtop = 0
    }
    [console]::windowtop = $newtop
}


Set-PSReadlineKeyHandler -Key Alt+w -BriefDescription ToggleBufferWidth -LongDescription "Toggle console buffer width" -vimode command -ScriptBlock {
    param($key, $arg)
    
    if ([console]::bufferwidth -eq $global:psreadlinefunctions_consolebufferwidthsave){
        [console]::bufferwidth = 2500
    }else{
        [console]::bufferwidth = $script:psreadlinefunctions_consolebufferwidthsave
    }
}

Set-PSReadlineKeyHandler -Key Alt+w -BriefDescription ToggleBufferWidth -LongDescription "Toggle console buffer width" -vimode insert -ScriptBlock {
    param($key, $arg)
    
    if ([console]::bufferwidth -eq $global:psreadlinefunctions_consolebufferwidthsave){
        [console]::bufferwidth = 2500
    }else{
        [console]::bufferwidth = $script:psreadlinefunctions_consolebufferwidthsave
    }
}

Set-PSReadlineKeyHandler -Key 'c,i' `
                         -BriefDescription ViReplaceInside `
                         -LongDescription "Replace Inside" `
                         -ViMode Command `
                         -ScriptBlock {
    param($key, $arg)

    #go into insert mode, to get a real cursor value below
    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($null,$null)

    [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode($null,$null)

    $key = [Console]::ReadKey($true)

    if ([int]$key.keychar -eq 27){
        return
    }

    switch ('{0:x}' -f [int]$key.keychar){
        
        #w
        '77'{

            if ($line[$cursor] -eq " "){
                if ($cursor -gt $line.count-1){
                    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardChar($null,$null)
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertWithAppend($null,$null)
                } else{
                    [Microsoft.PowerShell.PSConsoleReadLine]::BackwardChar($null,$null)
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertWithDelete($null,$null)
                }
            }else{

                if ($cursor -gt 0 -and "$((get-psreadlineoption).WordDelimiters) ".tochararray() -notcontains $line[$cursor-1]){
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViBackwardWord($null,$null)
                }
                
                [Microsoft.PowerShell.PSConsoleReadLine]::DeleteEndOfWord($null,$null)
                [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)
            }

            break

        }
        #W
        '57'{

            if ($line[$cursor] -eq " "){
                if ($cursor -gt $line.count-1){
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertWithAppend($null,$null)
                } else{
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertWithDelete($null,$null)
                }
            }else{

                if ($cursor -gt 0 -and $line[$cursor-1] -ne " "){
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViBackwardGlob($null,$null)
                }

                [Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteEndOfGlob($null,$null)
                [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)
            }

            break

        }
        #()
        {$_ -in ('28','29')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('(')
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof(')')

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }
        #[]
        {$_ -in ('5b','5d')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('[')
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof(']')

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }

        #{}
        {$_ -in ('7b','7d')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('{')
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof('}')

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }
        #"
        '22'{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('"')
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof('"')

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }
        #'
        '27'{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof("'")
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof("'")

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }
        
    }
}

Set-PSReadlineKeyHandler -Key 'c,a' `
                         -BriefDescription ViReplaceInsideIncludingBoundaries `
                         -LongDescription "Replace Inside Including Boundaries" `
                         -ViMode Command `
                         -ScriptBlock {
    param($key, $arg)

    #go into insert mode, to get a real cursor value below
    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($null,$null)

    [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode($null,$null)

    $key = [Console]::ReadKey($true)

    if ([int]$key.keychar -eq 27){
        return
    }

    switch ('{0:x}' -f [int]$key.keychar){
        
        #()
        {$_ -in ('28','29')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('(')
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor).indexof(')')

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }
        #[]
        {$_ -in ('5b','5d')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('[')
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor).indexof(']')

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }

        #{}
        {$_ -in ('7b','7d')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('{')
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor).indexof('}')

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }
        #"
        '22'{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('"')
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor+1).indexof('"')

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex+1 , '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }
        #'
        '27'{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof("'")
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor+1).indexof("'")

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex +1, '')
            [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

            break

        }
        
    }
}

Set-PSReadlineKeyHandler -Key 'd,i' `
                         -BriefDescription ViDeleteInside `
                         -LongDescription "Delete Inside" `
                         -ViMode Command `
                         -ScriptBlock {
    param($key, $arg)

    #go into insert mode, to get a real cursor value below
    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($null,$null)

    [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode($null,$null)

    $key = [Console]::ReadKey($true)

    if ([int]$key.keychar -eq 27){
        return
    }

    switch ('{0:x}' -f [int]$key.keychar){
        
        #w
        '77'{

            if ($line[$cursor] -eq " "){
                if ($cursor -gt $line.count-1){
                    [Microsoft.PowerShell.PSConsoleReadLine]::DeleteChar($null,$null)
                } else{
                    [Microsoft.PowerShell.PSConsoleReadLine]::DeleteChar($null,$null)
                }
            }else{

                if ($cursor -gt 0 -and "$((get-psreadlineoption).WordDelimiters) ".tochararray() -notcontains $line[$cursor-1]){
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViBackwardWord($null,$null)
                }

                [Microsoft.PowerShell.PSConsoleReadLine]::DeleteEndOfWord($null,$null)
            }

            break

        }
        #W
        '57'{

            if ($line[$cursor] -eq " "){
                if ($cursor -gt $line.count-1){
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertWithAppend($null,$null)
                } else{
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertWithDelete($null,$null)
                }
            }else{

                if ($cursor -gt 0 -and $line[$cursor-1] -ne " "){
                    [Microsoft.PowerShell.PSConsoleReadLine]::ViBackwardGlob($null,$null)
                }

                [Microsoft.PowerShell.PSConsoleReadLine]::ViDeleteEndOfGlob($null,$null)
            }

            break

        }
        #()
        {$_ -in ('28','29')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('(')
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof(')')

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')

            break

        }
        #[]
        {$_ -in ('5b','5d')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('[')
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof(']')

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')

            break

        }

        #{}
        {$_ -in ('7b','7d')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('{')
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof('}')

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')

            break

        }
        #"
        '22'{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('"')
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof('"')

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')

            break

        }
        #'
        '27'{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof("'")
            if ($startCursor -lt 0){
                return
            }
            $startCursor += 1

            $replaceIndex = $line.substring($startCursor).indexof("'")

            if ($replaceIndex -lt 0){
                return
            }

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')

            break

        }
        
    }
}


Set-PSReadlineKeyHandler -Key 'd,a' `
                         -BriefDescription ViDeleteInsideIncludingBoundaries `
                         -LongDescription "Delete Inside Including Boundaries" `
                         -ViMode Command `
                         -ScriptBlock {
    param($key, $arg)

    #go into insert mode, to get a real cursor value below
    [Microsoft.PowerShell.PSConsoleReadLine]::ViInsertMode($null,$null)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($null,$null)

    [Microsoft.PowerShell.PSConsoleReadLine]::ViCommandMode($null,$null)

    $key = [Console]::ReadKey($true)

    if ([int]$key.keychar -eq 27){
        return
    }

    switch ('{0:x}' -f [int]$key.keychar){
        
        #()
        {$_ -in ('28','29')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('(')
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor).indexof(')')

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')

            break

        }
        #[]
        {$_ -in ('5b','5d')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('[')
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor).indexof(']')

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')

            break

        }

        #{}
        {$_ -in ('7b','7d')}{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('{')
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor).indexof('}')

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex , '')

            break

        }
        #"
        '22'{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof('"')
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor+1).indexof('"')

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex+1 , '')

            break

        }
        #'
        '27'{
            $startCursor = $line.substring(0,$cursor + 1).lastindexof("'")
            if ($startCursor -lt 0){
                return
            }

            $replaceIndex = $line.substring($startCursor+1).indexof("'")

            if ($replaceIndex -lt 0){
                return
            }

            $replaceIndex += 1

            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($startCursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($startCursor, $replaceIndex+1 , '')

            break

        }
        
    }
}

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadlineKeyHandler -Key 'Alt+(' `
                         -BriefDescription ParenthesizeSelection `
                         -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
                         -vimode insert `
                         -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadlineKeyHandler -Key 'Alt+(' `
                         -BriefDescription ParenthesizeSelection `
                         -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
                         -vimode command `
                         -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

Set-PSReadlineKeyHandler -Key 'Alt+y' `
                         -BriefDescription CommandToClipboard `
                         -LongDescription "Sends the command to the clipboard" `
                         -vimode insert `
                         -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '{' + $line + '}.tostring() | set-clipboard')
    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
}

Set-PSReadlineKeyHandler -Key 'ctrl+r' -BriefDescription PasteRegister -LongDescription "Paste Register" -ViMode Insert -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null

    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::insert('"')
    
    $key = [Console]::ReadKey($true)
    [Microsoft.PowerShell.PSConsoleReadLine]::delete($cursor,1)

    if ([int]$key.keychar -eq 27){
        return
    }

    switch ('{0:x}' -f [int]$key.keychar){
        
        #*
        '2a'{

            [Microsoft.PowerShell.PSConsoleReadLine]::Paste()

            break

        }
        default{
            return
        }
        
    }
}


Set-PSReadlineKeyHandler -Key 'ctrl+r' -function Redo -ViMode Command 

#todo
Set-PSReadlineKeyHandler -Key 'ctrl+/'  -BriefDescription 'Search within buffer'  -LongDescription 'Search within buffer' -vimode command  -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)


    [Microsoft.PowerShell.PSConsoleReadLine]::setcursorposition(0)
    [Microsoft.PowerShell.PSConsoleReadLine]::insertlineabove()
    $search = read-host -prompt 'Regex'
    [Microsoft.PowerShell.PSConsoleReadLine]::undo()
    [Microsoft.PowerShell.PSConsoleReadLine]::invokeprompt($null,$null)

    

    if ($search){
        $found = $line | select-string $search -all

        if ($found){

            while ($true){
                $char = [console]::readkey($true)

                if ($char.key -eq 'n' -and $char.modifiers -ne [System.ConsoleModifiers]::Shift){
                    
                    $next = $found.matches.index | where {$_ -gt $cursor} | select -first 1
                    if (-not $next){
                        $next = $found.matches[0].index
                    }

                    [Microsoft.PowerShell.PSConsoleReadLine]::setcursorposition($next)
                    $cursor = $next
                    
                }elseif ($char.key -eq 'n' -and $char.modifiers -eq [System.ConsoleModifiers]::Shift){
                    $next = $found.matches.index | where {$_ -lt $cursor} | select -last 1
                    if (-not $next){
                        $next = $found.matches[-1].index
                    }

                    [Microsoft.PowerShell.PSConsoleReadLine]::setcursorposition($next)
                    $cursor = $next
                }elseif ($char.key -eq 'q' -or $char.key -eq 'escape'){
                    break
                }


            }
        }
    }
}



