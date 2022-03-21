
$aliases = @{
    cat = 'get-content'
    grep = 'select-string'
    ls = 'get-childitem'
    ps = 'get-process'
    rm = 'remove-item'
    rmdir = 'remove-item'
    sort = 'sort-object'
    s = 'select-object'
    join = 'join-string'
    cred = 'get-credential'
}

foreach ($key in $aliases.keys){
    if (test-path "alias:$key"){
        remove-item "alias:$key" -confirm:$false -force
    }
    new-alias -name $key -value $aliases[$key] -confirm:$false
}

