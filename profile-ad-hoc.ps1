

if (get-psdrive 'Modules' -ea 0) {
    remove-psdrive 'Modules' -force -confirm:$false
}
if (get-childitem function:'Modules:' -ea 0) {
    remove-item function:'Modules:' -force -confirm:$false
}
if (get-childitem home:/.local/share/powershell/Modules -ea 0){
    new-psdrive -name 'Modules' -psprovider filesystem -root home:/.local/share/powershell/Modules -confirm:$false -scope global -erroraction stop

    function global:"Modules`:"(){
        set-location Modules:
    }
}

