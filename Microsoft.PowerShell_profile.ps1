#profile specific 
#$env:PSModulePath = "$psscriptroot\modules:$($env:PSModulePath)"
# $global:myprofile = $MyInvocation.MyCommand.Path

if (get-psdrive 'Home' -ea 0) {
    remove-psdrive 'Home' -force -confirm:$false
}
if ($env:HOME){
    new-psdrive -name 'Home' -psprovider filesystem -root $env:HOME -confirm:$false -scope global -erroraction stop
}

if (get-childitem function:'Home:' -ea 0) {
    remove-item function:'home:' -force -confirm:$false
}
function global:"Home`:"(){
    set-location Home:
}

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

if (get-childitem $env:HOME\downloads -ea 0){
    if (get-psdrive 'Downloads' -ea 0) {
        remove-psdrive 'Downloads' -force -confirm:$false
    }
    new-psdrive -name 'Downloads' -psprovider filesystem -root $env:HOME\downloads -confirm:$false -scope global -erroraction stop

    if (get-childitem function:'Downloads:' -ea 0) {
        remove-item function:'Downloads:' -force -confirm:$false
    }
    function global:"Downloads`:"(){
        set-location ProfileHome:
    }
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

$queryhub = (get-module QueryHub -list -erroraction silentlycontinue)
if ($queryhub){
    $queryhub | import-module 
}

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

if (get-childitem profilehome:\profile-ad-hoc.ps1 -ea 0) {
    . profilehome:\profile-ad-hoc.ps1
}
