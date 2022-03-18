
#clean up aliases that may not be set based on platform
$cmdletAliases = @{
    cat = 'get-content'
    grep = 'select-string'
    ls = 'get-childitem'
    ps = 'get-process'
    rm = 'remove-item'
    rmdir = 'remove-item'
    sort = 'sort-object'
}

foreach ($key in $cmdletaliases.keys){
    if (test-path "alias:$key"){
        remove-item "alias:$key" -confirm:$false -force
    }
    new-alias -name $key -value $cmdletAliases[$key] -confirm:$false
}
