
$FormatEnumerationLimit = 3 

Update-FormatData -PrependPath ProfileHome:\formatting-files\MatchInfo.Format.ps1xml

$MatchInfoPreference = @{
    Prefix = '--> '
    MatchVTSeq = $PSStyle.foreground.brightgreen
    PathVTSeq = $PSStyle.Foreground.brightblack
    NumberVTSeq = $PSStyle.foreground.Brightblack
    ContextVTSeq = $PSStyle.Foreground.white
}

#custom prompt
function prompt {
	$computername = $env:COMPUTERNAME
    if ($pssenderinfo -eq $null){
        $theColor = "darkgreen"
    }else{
        $theColor = "yellow"
    }

    Write-Host (get-date).tostring("HH:mm:ss ") -nonewline -foregroundcolor darkgray
    Write-Host "$($($env:USERNAME).tolower())@$($($env:COMPUTERNAME).tolower()) " -nonewline -foregroundcolor $theColor

    if (get-command Get-OracleDefaultQueryHubConnection -erroraction silentlycontinue){
        $connectionName = try{get-oracledefaultqueryhubconnection}catch{$null}
        if ($connectionName){
            $sid = get-oracleconnectionsession $connectionName | select -expand sid
            $connectionname = "[o:$($connectionname):$sid] " 
            $color = 'blue'
            if ($connectionname -match 'prod|mdm\.world'){
                $color = 'red'
            }
            write-host $connectionname -fore $color -nonewline
        }
    }

    if (get-command Get-SqlServerDefaultQueryHubConnection -erroraction silentlycontinue){
        $connectionName = try{Get-SqlServerDefaultQueryHubConnection}catch{$null}
        if ($connectionName){
            $sid = get-sqlserverconnectionsession $connectionName | s -expand sid
            $sid = "$sid"
            $connectionname = "(s:$($connectionname):$sid) " 
            $color = 'darkgray'
            write-host $connectionname -fore $color -nonewline
        }
    }

	Write-Host ("$((get-location).path)") -nonewline -foregroundcolor White

    if ($psversiontable.platform -eq 'unix'){
        $id = id
        if ($id -match '\(sudo\)'){
            Write-Host '#' -nonewline -foregroundcolor $theColor
        }else{
            Write-Host '$' -nonewline -foregroundcolor $theColor
        }
    }else{
        if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
            Write-Host '#' -nonewline -foregroundcolor $theColor
        }else{
            Write-Host '$' -nonewline -foregroundcolor $theColor
        }
    }
    write-output " "
}
