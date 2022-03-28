#profile specific 
$global:myprofile = "$psscriptroot\base-profile.ps1"
$env:PSModulePath = "$psscriptroot\modules:$($env:PSModulePath)"

if (get-psdrive 'ProfileHome' -ea 0) {
    remove-psdrive 'ProfileHome' -force -confirm:$false
}
new-psdrive -name 'ProfileHome' -psprovider filesystem -root $psscriptroot -confirm:$false -scope global -erroraction stop

if (get-childitem function:'ProfileHome:' -ea 0) {
    remove-item function:'profilehome:' -force -confirm:$false
}
function global:"ProfileHome`:"(){
    set-location ProfileHome:
}

#platform specific
if ($psversiontable.platform -eq 'unix'){

    $env:COMPUTERNAME = hostname
    $env:USERNAME = $env:USER
    set-location ~/
}else{
    #for git, when HOMEDRIVE and HOMESHARE are readonly
    $env:HOME = $env:USERPROFILE
    set-location c:\
}

#module imports
import-module profilehome:\profile-module.psm1


#default parameters
$PSDefaultParameterValues.("Format-Table:Autosize") = $true
$PSDefaultParameterValues.("Format-Table:Property") = "*"
$PSDefaultParameterValues.("Format-Wide:Autosize") = $true
$PSDefaultParameterValues.("Join-String:Separator") = [environment]::newline

#output formatting
. profilehome:\profile-formatting.ps1

#extension methods
. profilehome:\profile-extensions.ps1

#aliases
. profilehome:\profile-aliases.ps1

#psreadline
. profilehome:\profile-psreadline.ps1

